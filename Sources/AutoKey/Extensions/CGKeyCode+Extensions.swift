//
//  CGKeyCode+Extensions.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Foundation
import Carbon

extension CGKeyCode {
    
    /// Returns a human-readable display name for the key code
    var displayName: String {
        switch self {
        // Numbers
        case CGKeyCode(kVK_ANSI_0): return "0"
        case CGKeyCode(kVK_ANSI_1): return "1"
        case CGKeyCode(kVK_ANSI_2): return "2"
        case CGKeyCode(kVK_ANSI_3): return "3"
        case CGKeyCode(kVK_ANSI_4): return "4"
        case CGKeyCode(kVK_ANSI_5): return "5"
        case CGKeyCode(kVK_ANSI_6): return "6"
        case CGKeyCode(kVK_ANSI_7): return "7"
        case CGKeyCode(kVK_ANSI_8): return "8"
        case CGKeyCode(kVK_ANSI_9): return "9"
            
        // Letters
        case CGKeyCode(kVK_ANSI_A): return "A"
        case CGKeyCode(kVK_ANSI_B): return "B"
        case CGKeyCode(kVK_ANSI_C): return "C"
        case CGKeyCode(kVK_ANSI_D): return "D"
        case CGKeyCode(kVK_ANSI_E): return "E"
        case CGKeyCode(kVK_ANSI_F): return "F"
        case CGKeyCode(kVK_ANSI_G): return "G"
        case CGKeyCode(kVK_ANSI_H): return "H"
        case CGKeyCode(kVK_ANSI_I): return "I"
        case CGKeyCode(kVK_ANSI_J): return "J"
        case CGKeyCode(kVK_ANSI_K): return "K"
        case CGKeyCode(kVK_ANSI_L): return "L"
        case CGKeyCode(kVK_ANSI_M): return "M"
        case CGKeyCode(kVK_ANSI_N): return "N"
        case CGKeyCode(kVK_ANSI_O): return "O"
        case CGKeyCode(kVK_ANSI_P): return "P"
        case CGKeyCode(kVK_ANSI_Q): return "Q"
        case CGKeyCode(kVK_ANSI_R): return "R"
        case CGKeyCode(kVK_ANSI_S): return "S"
        case CGKeyCode(kVK_ANSI_T): return "T"
        case CGKeyCode(kVK_ANSI_U): return "U"
        case CGKeyCode(kVK_ANSI_V): return "V"
        case CGKeyCode(kVK_ANSI_W): return "W"
        case CGKeyCode(kVK_ANSI_X): return "X"
        case CGKeyCode(kVK_ANSI_Y): return "Y"
        case CGKeyCode(kVK_ANSI_Z): return "Z"
            
        // Special keys
        case CGKeyCode(kVK_Space): return "Space"
        case CGKeyCode(kVK_Return): return "Return"
        case CGKeyCode(kVK_Tab): return "Tab"
        case CGKeyCode(kVK_Delete): return "Delete"
        case CGKeyCode(kVK_Escape): return "Escape"
        case CGKeyCode(kVK_Command): return "Command"
        case CGKeyCode(kVK_Shift): return "Shift"
        case CGKeyCode(kVK_CapsLock): return "Caps Lock"
        case CGKeyCode(kVK_Option): return "Option"
        case CGKeyCode(kVK_Control): return "Control"
        case CGKeyCode(kVK_RightShift): return "Right Shift"
        case CGKeyCode(kVK_RightOption): return "Right Option"
        case CGKeyCode(kVK_RightControl): return "Right Control"
            
        // Arrow keys
        case CGKeyCode(kVK_LeftArrow): return "Left Arrow"
        case CGKeyCode(kVK_RightArrow): return "Right Arrow"
        case CGKeyCode(kVK_DownArrow): return "Down Arrow"
        case CGKeyCode(kVK_UpArrow): return "Up Arrow"
            
        // Function keys
        case CGKeyCode(kVK_F1): return "F1"
        case CGKeyCode(kVK_F2): return "F2"
        case CGKeyCode(kVK_F3): return "F3"
        case CGKeyCode(kVK_F4): return "F4"
        case CGKeyCode(kVK_F5): return "F5"
        case CGKeyCode(kVK_F6): return "F6"
        case CGKeyCode(kVK_F7): return "F7"
        case CGKeyCode(kVK_F8): return "F8"
        case CGKeyCode(kVK_F9): return "F9"
        case CGKeyCode(kVK_F10): return "F10"
        case CGKeyCode(kVK_F11): return "F11"
        case CGKeyCode(kVK_F12): return "F12"
            
        // Punctuation
        case CGKeyCode(kVK_ANSI_Semicolon): return ";"
        case CGKeyCode(kVK_ANSI_Equal): return "="
        case CGKeyCode(kVK_ANSI_Comma): return ","
        case CGKeyCode(kVK_ANSI_Minus): return "-"
        case CGKeyCode(kVK_ANSI_Period): return "."
        case CGKeyCode(kVK_ANSI_Slash): return "/"
        case CGKeyCode(kVK_ANSI_Grave): return "`"
        case CGKeyCode(kVK_ANSI_LeftBracket): return "["
        case CGKeyCode(kVK_ANSI_Backslash): return "\\"
        case CGKeyCode(kVK_ANSI_RightBracket): return "]"
        case CGKeyCode(kVK_ANSI_Quote): return "'"
            
        default:
            return "Key \(self)"
        }
    }
    
    /// Returns all commonly used key codes for the UI picker
    static var commonKeyCodes: [(CGKeyCode, String)] {
        return [
            // Letters
            (CGKeyCode(kVK_ANSI_A), "A"),
            (CGKeyCode(kVK_ANSI_B), "B"),
            (CGKeyCode(kVK_ANSI_C), "C"),
            (CGKeyCode(kVK_ANSI_D), "D"),
            (CGKeyCode(kVK_ANSI_E), "E"),
            (CGKeyCode(kVK_ANSI_F), "F"),
            (CGKeyCode(kVK_ANSI_G), "G"),
            (CGKeyCode(kVK_ANSI_H), "H"),
            (CGKeyCode(kVK_ANSI_I), "I"),
            (CGKeyCode(kVK_ANSI_J), "J"),
            (CGKeyCode(kVK_ANSI_K), "K"),
            (CGKeyCode(kVK_ANSI_L), "L"),
            (CGKeyCode(kVK_ANSI_M), "M"),
            (CGKeyCode(kVK_ANSI_N), "N"),
            (CGKeyCode(kVK_ANSI_O), "O"),
            (CGKeyCode(kVK_ANSI_P), "P"),
            (CGKeyCode(kVK_ANSI_Q), "Q"),
            (CGKeyCode(kVK_ANSI_R), "R"),
            (CGKeyCode(kVK_ANSI_S), "S"),
            (CGKeyCode(kVK_ANSI_T), "T"),
            (CGKeyCode(kVK_ANSI_U), "U"),
            (CGKeyCode(kVK_ANSI_V), "V"),
            (CGKeyCode(kVK_ANSI_W), "W"),
            (CGKeyCode(kVK_ANSI_X), "X"),
            (CGKeyCode(kVK_ANSI_Y), "Y"),
            (CGKeyCode(kVK_ANSI_Z), "Z"),
            
            // Numbers
            (CGKeyCode(kVK_ANSI_0), "0"),
            (CGKeyCode(kVK_ANSI_1), "1"),
            (CGKeyCode(kVK_ANSI_2), "2"),
            (CGKeyCode(kVK_ANSI_3), "3"),
            (CGKeyCode(kVK_ANSI_4), "4"),
            (CGKeyCode(kVK_ANSI_5), "5"),
            (CGKeyCode(kVK_ANSI_6), "6"),
            (CGKeyCode(kVK_ANSI_7), "7"),
            (CGKeyCode(kVK_ANSI_8), "8"),
            (CGKeyCode(kVK_ANSI_9), "9"),
            
            // Special keys
            (CGKeyCode(kVK_Space), "Space"),
            (CGKeyCode(kVK_Return), "Return"),
            (CGKeyCode(kVK_Tab), "Tab"),
            
            // Function keys
            (CGKeyCode(kVK_F1), "F1"),
            (CGKeyCode(kVK_F2), "F2"),
            (CGKeyCode(kVK_F3), "F3"),
            (CGKeyCode(kVK_F4), "F4"),
            (CGKeyCode(kVK_F5), "F5"),
            (CGKeyCode(kVK_F6), "F6"),
            (CGKeyCode(kVK_F7), "F7"),
            (CGKeyCode(kVK_F8), "F8"),
            (CGKeyCode(kVK_F9), "F9"),
            (CGKeyCode(kVK_F10), "F10"),
            (CGKeyCode(kVK_F11), "F11"),
            (CGKeyCode(kVK_F12), "F12")
        ]
    }
    
    /// Returns all commonly used modifier key codes for hotkey configuration
    static var modifierKeyCodes: [(CGKeyCode, String)] {
        return [
            (CGKeyCode(kVK_ANSI_A), "A"),
            (CGKeyCode(kVK_ANSI_B), "B"),
            (CGKeyCode(kVK_ANSI_C), "C"),
            (CGKeyCode(kVK_ANSI_D), "D"),
            (CGKeyCode(kVK_ANSI_E), "E"),
            (CGKeyCode(kVK_ANSI_F), "F"),
            (CGKeyCode(kVK_ANSI_G), "G"),
            (CGKeyCode(kVK_ANSI_H), "H"),
            (CGKeyCode(kVK_ANSI_I), "I"),
            (CGKeyCode(kVK_ANSI_J), "J"),
            (CGKeyCode(kVK_ANSI_K), "K"),
            (CGKeyCode(kVK_ANSI_L), "L"),
            (CGKeyCode(kVK_ANSI_M), "M"),
            (CGKeyCode(kVK_ANSI_N), "N"),
            (CGKeyCode(kVK_ANSI_O), "O"),
            (CGKeyCode(kVK_ANSI_P), "P"),
            (CGKeyCode(kVK_ANSI_Q), "Q"),
            (CGKeyCode(kVK_ANSI_R), "R"),
            (CGKeyCode(kVK_ANSI_S), "S"),
            (CGKeyCode(kVK_ANSI_T), "T"),
            (CGKeyCode(kVK_ANSI_U), "U"),
            (CGKeyCode(kVK_ANSI_V), "V"),
            (CGKeyCode(kVK_ANSI_W), "W"),
            (CGKeyCode(kVK_ANSI_X), "X"),
            (CGKeyCode(kVK_ANSI_Y), "Y"),
            (CGKeyCode(kVK_ANSI_Z), "Z"),
            (CGKeyCode(kVK_ANSI_1), "1"),
            (CGKeyCode(kVK_ANSI_2), "2"),
            (CGKeyCode(kVK_ANSI_3), "3"),
            (CGKeyCode(kVK_ANSI_4), "4"),
            (CGKeyCode(kVK_ANSI_5), "5"),
            (CGKeyCode(kVK_ANSI_6), "6"),
            (CGKeyCode(kVK_ANSI_7), "7"),
            (CGKeyCode(kVK_ANSI_8), "8"),
            (CGKeyCode(kVK_ANSI_9), "9"),
            (CGKeyCode(kVK_ANSI_0), "0"),
            (CGKeyCode(kVK_F1), "F1"),
            (CGKeyCode(kVK_F2), "F2"),
            (CGKeyCode(kVK_F3), "F3"),
            (CGKeyCode(kVK_F4), "F4"),
            (CGKeyCode(kVK_F5), "F5"),
            (CGKeyCode(kVK_F6), "F6"),
            (CGKeyCode(kVK_F7), "F7"),
            (CGKeyCode(kVK_F8), "F8"),
            (CGKeyCode(kVK_F9), "F9"),
            (CGKeyCode(kVK_F10), "F10"),
            (CGKeyCode(kVK_F11), "F11"),
            (CGKeyCode(kVK_F12), "F12")
        ]
    }
}
