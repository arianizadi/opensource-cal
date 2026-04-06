import Foundation

struct NutritionLabelParser {
    /// Parses OCR text lines from a nutrition label into a dictionary of nutrient values
    static func parse(lines: [String]) -> [String: Double] {
        var result: [String: Double] = [:]
        let allText = lines.joined(separator: "\n")
        let lowerText = allText.lowercased()

        // MARK: - Pass 1: Extract absolute values (e.g. "Total Fat 16g")

        let nutrientPatterns: [(keys: [String], resultKey: String, avoidKeys: [String])] = [
            (["calories"], "calories", ["from fat"]),
            (["total fat"], "totalFat", []),
            (["saturated fat", "sat. fat", "sat fat"], "saturatedFat", []),
            (["trans fat"], "transFat", []),
            (["polyunsaturated fat", "polyunsat. fat", "polyunsat fat"], "polyunsaturatedFat", []),
            (["monounsaturated fat", "monounsat. fat", "monounsat fat"], "monounsaturatedFat", []),
            (["cholesterol"], "cholesterol", []),
            (["sodium"], "sodium", []),
            (["total carbohydrate", "total carb", "total carbs"], "totalCarbohydrates", []),
            (["dietary fiber", "dietary fibre", "fibre", "fiber"], "dietaryFiber", ["total"]),
            (["total sugars", "total sugar"], "totalSugars", []),
            (["added sugars", "added sugar", "incl. added sugars", "includes added sugars", "incl added sugars"], "addedSugars", []),
            (["sugars"], "totalSugars", ["added", "total"]),
            (["protein"], "protein", []),
            (["vitamin d"], "vitaminD", []),
            (["calcium"], "calcium", []),
            (["iron"], "iron", []),
            (["potassium"], "potassium", []),
            (["vitamin a"], "vitaminA", []),
            (["vitamin c"], "vitaminC", []),
            (["vitamin e"], "vitaminE", []),
            (["vitamin k"], "vitaminK", []),
            (["thiamine", "thiamin"], "thiamine", []),
            (["riboflavin"], "riboflavin", []),
            (["niacin"], "niacin", []),
            (["pantothenic acid"], "pantothenicAcid", []),
            (["vitamin b6", "vit. b6", "vit b6"], "vitaminB6", []),
            (["biotin"], "biotin", []),
            (["folate", "folic acid"], "folate", []),
            (["vitamin b12", "vit. b12", "vit b12"], "vitaminB12", []),
            (["phosphorus", "phosphorous"], "phosphorus", []),
            (["magnesium"], "magnesium", []),
            (["zinc"], "zinc", []),
            (["copper"], "copper", []),
            (["manganese"], "manganese", []),
            (["selenium"], "selenium", []),
            (["iodine"], "iodine", []),
            (["chloride"], "chloride", []),
            (["fluoride"], "fluoride", []),
            (["chromium"], "chromium", []),
            (["molybdenum"], "molybdenum", []),
            (["choline"], "choline", []),
            (["caffeine"], "caffeine", []),
        ]

        // Process each line for absolute values
        for line in lines {
            let lower = line.lowercased().trimmingCharacters(in: .whitespaces)

            for pattern in nutrientPatterns {
                // Skip if we already have this nutrient
                if result[pattern.resultKey] != nil { continue }

                for key in pattern.keys {
                    guard lower.contains(key) else { continue }

                    // Check avoid keys
                    let shouldAvoid = pattern.avoidKeys.contains { lower.contains($0) }
                    if shouldAvoid { continue }

                    if let value = extractAbsoluteValue(from: lower, keyword: key) {
                        result[pattern.resultKey] = value
                    }
                }
            }
        }

        // MARK: - Pass 1.5: Check adjacent lines for calories
        // Calories sometimes appears as "Calories" on one line, value on next
        if result["calories"] == nil {
            for (i, line) in lines.enumerated() {
                let lower = line.lowercased().trimmingCharacters(in: .whitespaces)
                if lower.contains("calories") && !lower.contains("from fat") {
                    // Try extracting from this line first
                    if let value = extractAbsoluteValue(from: lower, keyword: "calories") {
                        result["calories"] = value
                        break
                    }
                    // Try the next line
                    if i + 1 < lines.count {
                        let nextLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
                        if let value = Double(nextLine.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                            result["calories"] = value
                            break
                        }
                    }
                    // Try the previous line (number might come before)
                    if i > 0 {
                        let prevLine = lines[i - 1].trimmingCharacters(in: .whitespaces)
                        if let value = Double(prevLine.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                            result["calories"] = value
                            break
                        }
                    }
                }
            }
        }

        // MARK: - Pass 2: Convert %DV to absolute values for missing nutrients

        // Note: Calories are excluded — labels don't show %DV for calories
        let dvTable: [(key: String, dailyValue: Double, patterns: [String])] = [
            ("totalFat", 78, ["total fat"]),
            ("saturatedFat", 20, ["saturated fat", "sat. fat", "sat fat"]),
            ("cholesterol", 300, ["cholesterol"]),
            ("sodium", 2300, ["sodium"]),
            ("totalCarbohydrates", 275, ["total carbohydrate", "total carb"]),
            ("dietaryFiber", 28, ["dietary fiber", "fibre", "fiber"]),
            ("addedSugars", 50, ["added sugar"]),
            ("protein", 50, ["protein"]),
            ("vitaminD", 20, ["vitamin d"]),
            ("calcium", 1300, ["calcium"]),
            ("iron", 18, ["iron"]),
            ("potassium", 4700, ["potassium"]),
            ("vitaminA", 900, ["vitamin a"]),
            ("vitaminC", 90, ["vitamin c"]),
            ("vitaminE", 15, ["vitamin e"]),
            ("vitaminK", 120, ["vitamin k"]),
            ("thiamine", 1.2, ["thiamine", "thiamin"]),
            ("riboflavin", 1.3, ["riboflavin"]),
            ("niacin", 16, ["niacin"]),
            ("pantothenicAcid", 5, ["pantothenic acid"]),
            ("vitaminB6", 1.7, ["vitamin b6"]),
            ("biotin", 30, ["biotin"]),
            ("folate", 400, ["folate", "folic acid"]),
            ("vitaminB12", 2.4, ["vitamin b12"]),
            ("phosphorus", 1250, ["phosphorus", "phosphorous"]),
            ("magnesium", 420, ["magnesium"]),
            ("zinc", 11, ["zinc"]),
            ("copper", 0.9, ["copper"]),
            ("manganese", 2.3, ["manganese"]),
            ("selenium", 55, ["selenium"]),
            ("iodine", 150, ["iodine"]),
            ("chloride", 2300, ["chloride"]),
            ("chromium", 35, ["chromium"]),
            ("molybdenum", 45, ["molybdenum"]),
            ("choline", 550, ["choline"]),
        ]

        for entry in dvTable {
            // Only fill in if we don't already have an absolute value
            if result[entry.key] != nil { continue }

            for pattern in entry.patterns {
                if let percent = extractPercentDV(from: lowerText, keyword: pattern) {
                    result[entry.key] = (percent / 100.0) * entry.dailyValue
                    break
                }
            }
        }

        // MARK: - Pass 3: Cross-validate with %DV where possible
        // If we have both absolute and %DV, and they disagree significantly,
        // prefer the %DV-derived value (it's printed, less OCR error)
        for entry in dvTable {
            guard let currentValue = result[entry.key], currentValue > 0 else { continue }

            for pattern in entry.patterns {
                if let percent = extractPercentDV(from: lowerText, keyword: pattern), percent > 0 {
                    let dvDerived = (percent / 100.0) * entry.dailyValue
                    let ratio = currentValue / dvDerived
                    // If the absolute value differs by more than 20% from %DV-derived, use %DV
                    if ratio < 0.75 || ratio > 1.25 {
                        result[entry.key] = dvDerived
                    }
                    break
                }
            }
        }

        return result
    }

    // MARK: - Extraction Helpers

    /// Extract an absolute numeric value after a keyword (e.g. "Total Fat 16g" -> 16)
    private static func extractAbsoluteValue(from text: String, keyword: String) -> Double? {
        guard let range = text.range(of: keyword) else { return nil }
        let afterKeyword = String(text[range.upperBound...])

        // Match a number followed by a unit (not a %)
        // We want to avoid matching a bare percentage
        let patterns = [
            #"^\s*<?(\d+\.?\d*)\s*(mg|mcg|µg|g|kcal|cal)\b"#,  // With unit
            #"^\s*<?(\d+\.?\d*)\s*$"#,                            // Just a number at end of line
            #"^\s*<?(\d+\.?\d*)\s+[^%]"#,                         // Number followed by non-%
            #"^\s*<?(\d+\.?\d*)\s*(?:mg|mcg|µg|g|kcal|cal|$)"#,  // Flexible
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: afterKeyword, range: NSRange(afterKeyword.startIndex..., in: afterKeyword)),
               let numberRange = Range(match.range(at: 1), in: afterKeyword),
               let value = Double(afterKeyword[numberRange]) {
                return value
            }
        }

        // Fallback: just grab the first number that isn't immediately followed by %
        let fallback = #"<?(\d+\.?\d*)\s*(?:mg|mcg|µg|g|kcal|cal)?"#
        if let regex = try? NSRegularExpression(pattern: fallback),
           let match = regex.firstMatch(in: afterKeyword, range: NSRange(afterKeyword.startIndex..., in: afterKeyword)),
           let numberRange = Range(match.range(at: 1), in: afterKeyword) {
            let value = Double(afterKeyword[numberRange])

            // Check this isn't actually a % value
            let fullMatchRange = Range(match.range, in: afterKeyword)!
            let afterMatch = String(afterKeyword[fullMatchRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            if afterMatch.hasPrefix("%") { return nil }

            return value
        }

        return nil
    }

    /// Extract a %DV value for a nutrient from the full text
    private static func extractPercentDV(from text: String, keyword: String) -> Double? {
        // Look for patterns like "vitamin a 25%" or "vitamin a ... 25%"
        // The % may be on the same line or nearby
        let patterns = [
            // "keyword ... Ng ... N%" - take the percentage
            keyword + #"[^\n]*?(\d+\.?\d*)\s*%"#,
            // "keyword\n...N%" on next line
            keyword + #"[^\n]*\n[^\n]*?(\d+\.?\d*)\s*%"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let numRange = Range(match.range(at: 1), in: text),
               let percent = Double(text[numRange]) {
                // Sanity check: % should be 0-1000
                if percent > 0 && percent <= 1000 {
                    return percent
                }
            }
        }

        return nil
    }
}
