//
//  WKDelegate.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 7/8/2022.
//

import Foundation
import WatchKit
import os


class WKDelegate: NSObject, WKExtensionDelegate {
    // The OVMS-Watch app's data model
    lazy var model = ServerData.shared
    
    let logger = Logger(subsystem:
                            "au.com.prhenterprises.OVMS-Watch.watchkitapp.watchkitextension.complicationcontroller",
                        category: "Delegate")
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        logger.debug("Finished Launching")
    }
    
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        logger.debug("Became Active")
        Task {
            switch carMode {
            case .charging:
                model.charge = await model.charge.getCharge()
                model.chargePercent = Double(model.charge.soc) ?? 0.0
            case .driving:
                model.status = await model.status.getStatus()
                model.chargePercent = Double(model.status.soc) ?? 0.0
            default:
                model.status = await model.status.getStatus()
                model.chargePercent = Double(model.status.soc) ?? 0.0
            }
            logger.debug("Became Active Charge % = \(self.model.chargePercent)")
        }
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        logger.debug("Resign Active")
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let urlBackgroundTask as WKURLSessionRefreshBackgroundTask:
                logger.debug("WKURLSessionRefreshBackgroundTask task received")
                //currMode = mode.identifier
                //chargePercent = Double(charge.soc) ?? 0.0
                updateActiveComplications()
                //self.addBackgroundRefreshTask(urlBackgroundTask)
                urlBackgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                logger.debug("WKSnapshotRefreshBackgroundTask task received")
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
