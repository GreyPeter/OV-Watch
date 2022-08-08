//
//  ServerData.swift
//  OVMS-Watch Watch App
//
//  Created by Peter Harry on 6/8/2022.
//

import Foundation
import ClockKit
import os

enum Endpoint {
    static let identifierKey = "identifier"
    case charge
    case status
    case vehicles
    case vehicle
    case cookie
    case token
    case location
    var path: String {
        switch self {
        case .charge:
            return "/api/charge/"
        case .status:
            return "/api/status/"
        case .vehicles:
            return "/api/vehicles"
        case .vehicle:
            return "/api/vehicle/"
        case .cookie:
            return "/api/cookie"
        case .token:
            return "/api/token"
        case .location:
            return "/api/location/"
        }
    }
    var identifier: String {
        switch self {
        case .charge:
            return "Charge"
        case .status:
            return "Status"
        case .vehicles:
            return "Vehicles"
        case .vehicle:
            return "Vehicle"
        case .cookie:
            return "Cookie"
        case .token:
            return "Token"
        case .location:
            return "Location"
        }
    }
}

enum Mode {
    static let identifierKey = "identifier"
    case driving
    case charging
    case idle
    var identifier: String {
        switch self {
        case .driving:
            return "D"
        case .charging:
            return "C"
        case .idle:
            return "I"
        }
    }
}

enum DownloadStatus {
    case notStarted
    case queued
    case inProgress(Double)
    case completed
    case failed(Error)
}

public var lastSOC = 0
var currentToken = Token.initial
var vehicles = Vehicle.dummy
let keyChainService = KeychainService()
var userName = ""
var carMode: Mode = .charging

class ServerData: NSObject, ObservableObject {
    let logger = Logger(subsystem:
                            "au.com.prhenterprises.OVMS-Watch.watchkitapp.watchkitextension.complicationcontroller",
                        category: "Server")
    static let shared = ServerData()
    var charge: Charge = Charge.dummy
    var status: Status = Status.dummy
    var location: Location = Location.dummy
    @Published var chargePercent: Double = Double(Charge.dummy.soc) ?? 0.0
    //@Published var currMode = Mode.charging.identifier
    var endpoint = Endpoint.charge
    var endpointToggle = false
    var downloadData: Data = Data()
    private var downloadStatus = DownloadStatus.notStarted
    
    private var sessionID: String {
        "\(Bundle.main.bundleIdentifier!).background"
    }
    
    
    private lazy var backgroundURLSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: sessionID)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    func startBackgroundDownload() {
        
        switch carMode {
        case .driving:
            endpoint = endpointToggle == true ? Endpoint.location : Endpoint.status
        case .charging:
            endpoint = Endpoint.charge
        case .idle:
            endpoint = Endpoint.status
        }
        let scheduledDate = Date().addingTimeInterval(15 * 60)
        
        if let url = URL(string: getURL(for: endpoint)!) {
            
            let bgDload = backgroundURLSession.downloadTask(with: url)
            bgDload.earliestBeginDate = scheduledDate
            bgDload.countOfBytesClientExpectsToSend = 200
            bgDload.countOfBytesClientExpectsToReceive = 1024
            //BackgroundURLSessions.sharedInstance().sessions[sessionID] = self
            
            logger.debug("Next download update = \(scheduledDate.formatted(date: .omitted, time: .standard))")
            bgDload.resume()
            downloadStatus = .queued
        }
    }
}

extension ServerData: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo loc: URL) {
        
        // We don't need more updates on this session, so let it go.
        //BackgroundURLSessions.sharedInstance().sessions[sessionID] = nil
        if loc.isFileURL {
            do {
                downloadData = try Data(contentsOf: loc)
            } catch {
                logger.debug("could not read data from \(loc)")
            }
        }
        DispatchQueue.main.async { [self] in
            saveDownloadedData(downloadData)
            //currMode = mode.identifier
            self.downloadStatus = .completed
        }
    }
    
    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if error != nil {
            logger.debug("Download Error in task: \(task.taskIdentifier)")
            //task.cancel()
        } else {
            //task.cancel()
            logger.debug("Task finished: \(task.taskIdentifier)")
            startBackgroundDownload()
            updateActiveComplications()
        }
    }
    
    private func saveDownloadedData(_ data: Data) {
        logger.debug("Download Finished")
        do {
            switch carMode {
            case .charging:
                charge = try JSONDecoder().decode(Charge.self, from: downloadData)
                chargePercent = Double(charge.soc) ?? 0.0
                if charge.charging == 0 {
                    carMode = charge.caron == 0 ? .idle : .driving
                }
            case .idle:
                status = try JSONDecoder().decode(Status.self, from: downloadData)
                chargePercent = Double(status.soc) ?? 0.0
                if status.charging != 0 {
                    carMode = .charging
                } else {
                    carMode = status.caron == 0 ? .idle : .driving
                }
            case .driving:
                if endpointToggle == true {
                    location = try JSONDecoder().decode(Location.self, from: downloadData)
                } else {
                    status = try JSONDecoder().decode(Status.self, from: downloadData)
                    chargePercent = Double(status.soc) ?? 0.0
                    if status.charging != 0 {
                        carMode = .charging
                    } else {
                        carMode = status.caron == 0 ? .idle : .driving
                    }
                }
            }
            logger.debug("Mode: \(carMode.identifier) SOC:\(self.charge.soc)/\(self.status.soc) Charge:\(self.charge.chargestate)/\(self.status.chargestate) Car:\(self.charge.caron == 0 ? "OFF" : "ON")/\(self.status.caron == 0 ? "OFF" : "ON")")
        }
        catch {
            print("Error converting server response to json - Endpoint = \(endpoint) Mode = \(carMode)")
        }
    }
}


func getURL(for endpoint: Endpoint) -> String? {
    var vehicleID = vehicles[0].id
    if endpoint.identifier == "Vehicles" || endpoint.identifier == "Cookie" {
        vehicleID = ""
    }
    if endpoint.identifier == "Token" {
        vehicleID = "/\(currentToken.token)"
    }
    var password = keyChainService.retrievePassword(for: userName) ?? ""
    if currentToken.token != "" && endpoint.identifier != "Token" {
        password = currentToken.token
    }
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = "api.openvehicles.com"
    urlComponents.port = 6869
    urlComponents.path = "\(endpoint.path)\(vehicleID)/"
    urlComponents.query = "username=\(userName)&password=\(String(describing: password))"
    return urlComponents.url?.absoluteString
}

func updateActiveComplications() {
    print("Updating Active Compications")
    let complicationServer = CLKComplicationServer.sharedInstance()
    if let activeComplications = complicationServer.activeComplications {
        for complication in activeComplications {
            complicationServer.reloadTimeline(for: complication)
        }
    }
}


