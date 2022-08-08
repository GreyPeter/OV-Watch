//
//  ComplicationController.swift
//  OV-Watch WatchKit Extension
//
//  Created by Peter Harry on 8/8/2022.
//

import ClockKit
import os
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    let logger = Logger(subsystem:
                            "au.com.prhenterprises.OVMS-Watch.watchkitapp.watchkitextension.complicationcontroller",
                        category: "Complication")
    
    // The OVMS-Watch app's data model
    lazy var model = ServerData.shared
    
    // MARK: - Timeline Configuration
    
    // Define how far into the future the app can provide data.
    func timelineEndDate(for complication: CLKComplication) async -> Date? {
        
        // Indicate that the app can provide timeline entries for the next 24 hours.
        Date().addingTimeInterval(15.0 * 60.0)
    }

    // Define whether the complication is visible when the watch is unlocked.
    func privacyBehavior(for complication: CLKComplication) async -> CLKComplicationPrivacyBehavior {

        // This is potentially sensitive data. Hide it on the lock screen.
        .showOnLockScreen
    }

    func complicationDescriptors() async -> [CLKComplicationDescriptor] {
        logger.debug("Accessing the complication descriptors.")
        let descriptor = CLKComplicationDescriptor(identifier: "OVMS_Vehicle_Data",
                                                   displayName: "Vehicle Data",
                                                   supportedFamilies: CLKComplicationFamily.allCases)
        return [descriptor]
    }
    
    // MARK: - Complication Configuration
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    // MARK: - Timeline Population
    
    // Return the current timeline entry.
    func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? {
        logger.debug("Accessing the current timeline entry.")
        return createTimelineEntry(forComplication: complication, date: Date())
    }
    
    // Return future timeline entries.
    func timelineEntries(for complication: CLKComplication,
                         after date: Date,
                         limit: Int) async -> [CLKComplicationTimelineEntry]? {
        //logger.debug("Accessing timeline entries for dates after \(DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)).")

        let minutes = 60.0
        let fifteenMinutes = 15.0 * 60.0

        // Create an array to hold the timeline entries.
        var entries: [CLKComplicationTimelineEntry] = []

        // Calculate the start and end dates.
        var current = date.addingTimeInterval(minutes)
        let endDate = date.addingTimeInterval(fifteenMinutes)

        // Create a timeline entry for every minute from the starting time.
        // Stop once you reach the limit or the end date.
        while current < endDate && entries.count < limit {
            entries.append(createTimelineEntry(forComplication: complication, date: current))
            current = current.addingTimeInterval(minutes)
        }
        return entries
    }

    // MARK: - Placeholder Templates

    // Return a localized template with generic information.
    // The system displays the placeholder in the complication selector.
    func localizableSampleTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
        
        // Calculate the date 15 minutes from now.
        // Since it's more than 15 minutes in the future
        
        let future = Date().addingTimeInterval(15.0 * 60.0)
        return createTemplate(forComplication: complication, date: future)
    }
    
    //    We don't need to implement this method because our privacy behavior is hideOnLockScreen.
    //    Always-On Time automatically hides complications that would be hidden when the device is locked
    //    func alwaysOnTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
    //    }

    // MARK: - Private Methode
    
    // Return a timeline entry for the specified complication and date.
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry {
        
        // Get the correct template based on the complication.
        let template = createTemplate(forComplication: complication, date: date)
        
        // Use the template and date to create a timeline entry.
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }

    // Select the correct template based on the complication's family.
    private func createTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(forDate: date)
        case .modularLarge:
            return createModularLargeTemplate(forDate: date)
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createUtilitarianSmallFlatTemplate(forDate: date)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(forDate: date)
        case .circularSmall:
            return createCircularSmallTemplate(forDate: date)
        case .extraLarge:
            return createExtraLargeTemplate(forDate: date)
        case .graphicCorner:
            return createGraphicCornerTemplate(forDate: date)
        case .graphicCircular:
            return createGraphicCircleTemplate(forDate: date)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(forDate: date)
        case .graphicBezel:
            return createGraphicBezelTemplate(forDate: date)
        case .graphicExtraLarge:
            return createGraphicExtraLargeTemplate(forDate: date)
    
        @unknown default:
            logger.error("Unknown Complication Family")
            fatalError()
        }
    }

    // Return a modular small template.
    private func createModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        
        // Create the template using the providers.
        return CLKComplicationTemplateModularSmallStackText(line1TextProvider: soc,
                                                            line2TextProvider: units)
    }
    
    // Return a modular large template.
    private func createModularLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let titleTextProvider = CLKSimpleTextProvider(text: "Current Charge", shortText: "Charge")

        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        let combinedSOCProvider = CLKTextProvider(format: "%@ %@", soc, units)
        
        // Create the template using the providers.
        //let imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeModularLarge"))
        return CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: titleTextProvider, body1TextProvider: combinedSOCProvider)
    }
    
    // Return a utilitarian small flat template.
    private func createUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        //let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        let combinedSOCProvider = CLKTextProvider(format: "%@ %@", soc, units)
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: combinedSOCProvider)
    }
    
    // Return a utilitarian large template.
    private func createUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        //let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        let combinedSOCProvider = CLKTextProvider(format: "%@ %@", soc, units)
        
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: combinedSOCProvider)
    }
    
    // Return a circular small template.
    private func createCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        let combinedSOCProvider = CLKTextProvider(format: "%@ %@", soc, units)
        
        // Create the template using the providers.
        return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: combinedSOCProvider, line2TextProvider: combinedSOCProvider)
    }
    
    // Return an extra large template.
    private func createExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        
        // Create the template using the providers.
        return CLKComplicationTemplateExtraLargeStackText(line1TextProvider: soc,
                                                          line2TextProvider: units)
    }
    
    // Return a graphic template that fills the corner of the watch face.
    private func createGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let percentage = Float(model.chargePercent/100)
        let rounded = String(Int(model.chargePercent.rounded()))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.red, .orange, .yellow, .green],
                                                   gaugeColorLocations: [0.25, 0.5, 0.75, 1.0] as [NSNumber],
                                                   fillFraction: percentage)
        let labelProvider = CLKTextProvider(format: "%@", rounded)
        
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCornerGaugeText(gaugeProvider: gaugeProvider, outerTextProvider: labelProvider)
    }
    
    // Return a graphic circle template.
    private func createGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        var currentPercentage = Double(model.status.soc) ?? 1.0
        var range = Double(model.status.estimatedrange)
        switch carMode {
        case .charging:
            currentPercentage = model.charge.futureSOC(forDate: date)
            range = model.charge.calculateRange(forCharge: currentPercentage)
        case .driving:
            break
        default:
            break
        }
        let percentage = Float(currentPercentage/100)
        let rounded = String(Int(currentPercentage.rounded()))
        let roundedRange = String(Int(range?.rounded() ?? 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.red, .orange, .yellow, .green],
                                                   gaugeColorLocations: [0.25, 0.5, 0.75, 1.0] as [NSNumber],
                                                   fillFraction: percentage)
        let bottomText = CLKTextProvider(format: "%@%%", rounded)
        let centerText = CLKTextProvider(format: "%@", roundedRange)
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText(gaugeProvider: gaugeProvider,
                                                                         bottomTextProvider: bottomText,
                                                                         centerTextProvider: centerText)
    }
    
    // Return a large rectangular graphic template.
    private func createGraphicRectangularTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        var currentPercentage = Double(model.status.soc) ?? 1.0
        var range = Double(model.status.estimatedrange)
        switch carMode {
        case .charging:
            currentPercentage = model.charge.futureSOC(forDate: date)
            range = model.charge.calculateRange(forCharge: currentPercentage)
        case .driving:
            break
        default:
            break
        }
        let percentage = Float(currentPercentage/100)
        let rounded = String(round(currentPercentage * 100) / 100)
        let roundedRange = String(Int(range?.rounded() ?? 1.0))
        logger.debug("Percentage = \(rounded) Range = \(roundedRange) @ \(DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)).")
        let titleTextProvider = CLKSimpleTextProvider(text: "Charge = \(rounded)%", shortText: "Charge")
        let combinedSOCProvider = CLKTextProvider(format: "Range %@%@", roundedRange, model.status.units)

        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.red, .orange, .yellow, .green],
                                                   gaugeColorLocations: [0.25, 0.5, 0.75, 1.0] as [NSNumber],
                                                   fillFraction: percentage)

        // Create the template using the providers.
        
        //return CLKComplicationTemplateGraphicRectangularTextGauge(headerImageProvider: imageProvider,headerTextProvider: titleTextProvider,body1TextProvider: combinedSOCProvider,gaugeProvider: gaugeProvider)
        return CLKComplicationTemplateGraphicRectangularTextGauge(headerTextProvider: titleTextProvider, body1TextProvider: combinedSOCProvider, gaugeProvider: gaugeProvider)
    }
    
    // Return a circular template with text that wraps around the top of the watch's bezel.
    private func createGraphicBezelTemplate(forDate date: Date) -> CLKComplicationTemplate {
        
        // Create a graphic circular template with an image provider.
        let circle = CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "OVMS")))
        // Create the text provider.
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let units = CLKSimpleTextProvider(text: "%")
        let combinedSOCProvider = CLKTextProvider(format: "%@ %@", soc, units)
        
        // Create the bezel template using the circle template and the text provider.
        return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circle,
                                                               textProvider: combinedSOCProvider)
    }
    
    // Returns an extra large graphic template.
    private func createGraphicExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        
        // Create the data providers.
        let percentage = Float(model.chargePercent/100)
        let rounded = String(Int(model.chargePercent.rounded()))
        let soc = CLKSimpleTextProvider(text: rounded)
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.red, .orange, .yellow, .green],
                                                   gaugeColorLocations: [0.25, 0.5, 0.75, 1.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        return CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText(
            gaugeProvider: gaugeProvider,
            bottomTextProvider: CLKSimpleTextProvider(text: "%"),
            centerTextProvider: soc)
    }
    
}
