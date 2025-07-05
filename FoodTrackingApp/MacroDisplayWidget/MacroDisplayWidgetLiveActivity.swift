//
//  MacroDisplayWidgetLiveActivity.swift
//  MacroDisplayWidget
//
//  Created by Cem Beyenal on 7/5/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MacroDisplayWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MacroDisplayWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MacroDisplayWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MacroDisplayWidgetAttributes {
    fileprivate static var preview: MacroDisplayWidgetAttributes {
        MacroDisplayWidgetAttributes(name: "World")
    }
}

extension MacroDisplayWidgetAttributes.ContentState {
    fileprivate static var smiley: MacroDisplayWidgetAttributes.ContentState {
        MacroDisplayWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MacroDisplayWidgetAttributes.ContentState {
         MacroDisplayWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MacroDisplayWidgetAttributes.preview) {
   MacroDisplayWidgetLiveActivity()
} contentStates: {
    MacroDisplayWidgetAttributes.ContentState.smiley
    MacroDisplayWidgetAttributes.ContentState.starEyes
}
