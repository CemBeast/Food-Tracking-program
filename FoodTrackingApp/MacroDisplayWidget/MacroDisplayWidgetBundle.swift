//
//  MacroDisplayWidgetBundle.swift
//  MacroDisplayWidget
//
//  Created by Cem Beyenal on 7/5/25.
//

import WidgetKit
import SwiftUI

@main
struct MacroDisplayWidgetBundle: WidgetBundle {
    var body: some Widget {
        MacroDisplayWidget()
        MacroDisplayWidgetControl()
        MacroDisplayWidgetLiveActivity()
    }
}
