import Foundation
import SwiftUI

// MARK: - App Mode

enum AppMode: String, CaseIterable {
    case tracker = "Tracker"
    case limit = "Limit"

    var description: String {
        switch self {
        case .tracker: return "Track what you eat without calorie limits"
        case .limit: return "Set goals based on your body stats"
        }
    }
}

// MARK: - Profile Enums

enum BiologicalSex: String, CaseIterable {
    case male = "Male"
    case female = "Female"
}

enum ActivityLevel: String, CaseIterable {
    case sedentary = "Sedentary"
    case light = "Lightly Active"
    case moderate = "Moderately Active"
    case active = "Very Active"
    case extreme = "Extremely Active"

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .extreme: return 1.9
        }
    }

    var shortLabel: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .active: return "Active"
        case .extreme: return "Extreme"
        }
    }
}

enum WeightGoal: String, CaseIterable {
    case lose = "Lose Weight"
    case maintain = "Maintain"
    case gain = "Gain Weight"

    var calorieAdjustment: Double {
        switch self {
        case .lose: return -500
        case .maintain: return 0
        case .gain: return 500
        }
    }
}

// MARK: - User Profile

@Observable
final class UserProfile {
    static let shared = UserProfile()

    // Stored properties that @Observable can track
    var mode: AppMode
    var sex: BiologicalSex
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var activityLevel: ActivityLevel
    var weightGoal: WeightGoal
    var useImperial: Bool
    var hasSetProfile: Bool

    private init() {
        let defaults = UserDefaults.standard
        self.mode = AppMode(rawValue: defaults.string(forKey: "appMode") ?? "") ?? .tracker
        self.sex = BiologicalSex(rawValue: defaults.string(forKey: "sex") ?? "") ?? .male
        self.age = { let v = defaults.integer(forKey: "age"); return v > 0 ? v : 25 }()
        self.heightCm = { let v = defaults.double(forKey: "heightCm"); return v > 0 ? v : 175 }()
        self.weightKg = { let v = defaults.double(forKey: "weightKg"); return v > 0 ? v : 70 }()
        self.activityLevel = ActivityLevel(rawValue: defaults.string(forKey: "activityLevel") ?? "") ?? .moderate
        self.weightGoal = WeightGoal(rawValue: defaults.string(forKey: "weightGoal") ?? "") ?? .maintain
        self.useImperial = defaults.bool(forKey: "useImperial")
        self.hasSetProfile = defaults.bool(forKey: "hasSetProfile")
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(mode.rawValue, forKey: "appMode")
        defaults.set(sex.rawValue, forKey: "sex")
        defaults.set(age, forKey: "age")
        defaults.set(heightCm, forKey: "heightCm")
        defaults.set(weightKg, forKey: "weightKg")
        defaults.set(activityLevel.rawValue, forKey: "activityLevel")
        defaults.set(weightGoal.rawValue, forKey: "weightGoal")
        defaults.set(useImperial, forKey: "useImperial")
        defaults.set(hasSetProfile, forKey: "hasSetProfile")
    }

    // MARK: - TDEE Calculation (Mifflin-St Jeor)

    var bmr: Double {
        if sex == .male {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        } else {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
    }

    var tdee: Double {
        bmr * activityLevel.multiplier
    }

    var calorieGoal: Double {
        max(tdee + weightGoal.calorieAdjustment, 1200)
    }

    // Macro targets based on balanced split: 30% protein, 40% carbs, 30% fat
    var proteinGoal: Double { (calorieGoal * 0.30) / 4 }
    var carbGoal: Double { (calorieGoal * 0.40) / 4 }
    var fatGoal: Double { (calorieGoal * 0.30) / 9 }

    // MARK: - Unit Conversion Helpers

    var displayHeight: String {
        if useImperial {
            let totalInches = heightCm / 2.54
            let feet = Int(totalInches) / 12
            let inches = Int(totalInches) % 12
            return "\(feet)'\(inches)\""
        }
        return "\(Int(heightCm)) cm"
    }

    var displayWeight: String {
        if useImperial {
            return "\(Int(weightKg * 2.205)) lbs"
        }
        return "\(Int(weightKg)) kg"
    }
}
