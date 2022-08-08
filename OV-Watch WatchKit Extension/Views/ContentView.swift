//
//  ContentView.swift
//  OV-Watch WatchKit Extension
//
//  Created by Peter Harry on 8/8/2022.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model: ServerData
    @Environment(\.scenePhase) var scenePhase
    var body: some View {
        GeometryReader { watchGeo in
            VStack {
                NavigationLink(
                    destination: Vehicles(model: model, vehicles: vehicles),
                    label: {
                        Image(systemName: "car")
                        Text(vehicles[0].id)
                            .font(.caption2)
                    })
                .frame(width: watchGeo.size.width * 0.79, height: watchGeo.size.height * 0.14)
                .padding()
                
                Image("battery_000")
                    .resizable()
                    .scaledToFit()
                    .frame(width: watchGeo.size.width * 0.9, height: watchGeo.size.height * 0.3, alignment: .center)
                    .frame(width: watchGeo.size.width, height: watchGeo.size.height * 0.3, alignment: .center)
                    .overlay(ProgressBar(value: model.chargePercent,
                                         maxValue: 100,
                                         backgroundColor: .clear,
                                         foregroundColor: color(forChargeLevel: model.chargePercent)
                                        )
                        .frame(width: watchGeo.size.width * 0.7, height: watchGeo.size.height * 0.25)
                        .frame(width: watchGeo.size.width, height: watchGeo.size.height * 0.25)
                        .opacity(0.6)
                        .padding(0)
                    )
                    .overlay(
                        VStack {
                            Text("\(carMode == .charging ? model.charge.soc : model.status.soc)%      \(carMode.identifier)")
                                .fontWeight(.bold)
                                .foregroundColor(Color.white)
                            Text("\(carMode == .charging ? model.charge.estimatedrange : model.status.estimatedrange)\(carMode == .charging ? model.charge.units : model.status.units)")
                                .fontWeight(.bold)
                                .foregroundColor(Color.white)
                        }
                            .background(Color.clear)
                            .opacity(0.9))
                switch carMode {
                case .charging:
                    SubView(Text1: "Full", Data1: timeConvert(time: model.charge.charge_etr_full), Text2: "\(model.charge.charge_limit_soc)%", Data2: timeConvert(time: model.charge.charge_etr_soc), Text3: "\(model.charge.charge_limit_range)\(model.charge.units)", Data3: timeConvert(time: model.charge.charge_etr_range), Text4: "Dur", Data4: timeConvert(time: "\((Int(model.charge.chargeduration) ?? 0)/60)"), Text5: "kWh", Data5: String(format:"%0.1f",(Float(model.charge.chargekwh) ?? 0.00) / 10), Text6: "@ kW", Data6: model.charge.chargepower)
                case .driving:
                    SubView(Text1: "Speed", Data1: model.location.speed, Text2: "PWR", Data2: model.location.power, Text3: "Trip", Data3: model.location.tripmeter, Text4: "Rxed", Data4: model.location.energyrecd, Text5: "Used", Data5: model.location.energyused, Text6: "Mode", Data6: model.location.drivemode)
                default:
                    SubView(Text1: "Motor", Data1: "\(model.status.temperature_motor)°", Text2: "Batt", Data2: "\(model.status.temperature_battery)°", Text3: "PEM", Data3: "\(model.status.temperature_pem)°", Text4: "Amb", Data4: "\(model.status.temperature_ambient)°", Text5: "Cabin", Data5: "\(model.status.temperature_cabin)°", Text6: "12V", Data6: model.status.vehicle12v)
                }
            }
            .task {
                if currentToken.application == "" {
                    await currentToken.getToken()
                }
                model.status = await model.status.getStatus()
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
                //print("Charge % = \(model.chargePercent)")
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                model.startBackgroundDownload()
                updateActiveComplications()
            default:
                print("Charge % = \(model.chargePercent)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let serverData = ServerData()
    static var previews: some View {
        ContentView(model: serverData)
    }
}
