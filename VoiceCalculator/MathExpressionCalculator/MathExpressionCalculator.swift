//
//  MathExpressionCalculator.swift
//  VoiceCalculator
//
//  Created by Filip Szukala on 11/06/2017.
//  Copyright © 2017 Filip Szukala. All rights reserved.
//

import Foundation

class MathExpressionCalculator {
    
    public class func parse(expression: String) -> Int {
        return parse(additionAndSubtraction: expression)
    }
    
    private class func parse(additionAndSubtraction expression: String) -> Int {
        let multiplicationParseResult = parse(multiplication: expression)
        var parsedNumber = multiplicationParseResult.0
        var expressionLeftToParse = multiplicationParseResult.1
        
        if expressionLeftToParse.characters.count > 0 {
            if expressionLeftToParse.characters.first == "+" {
                let parsedRightNumber = parse(additionAndSubtraction: expressionLeftToParse.dropFirstCharacter())
                parsedNumber += parsedRightNumber
            } else if expressionLeftToParse.characters.first == "-" {
                let parsedRightNumber = parse(additionAndSubtraction: expressionLeftToParse.dropFirstCharacter())
                parsedNumber -= parsedRightNumber
            }
        }
        
        return parsedNumber
    }
    
    private class func parse(multiplication expression: String) -> (Int, String) {
        let numberParseResult = parse(number: expression)
        var parsedNumber = numberParseResult.0
        var expressionLeftToParse = numberParseResult.1
        
        if expressionLeftToParse.characters.first == "×" {
            let rightSideMultiplicationParseResult = parse(multiplication: expressionLeftToParse.dropFirstCharacter())
            let parsedRightNumber = rightSideMultiplicationParseResult.0
            
            expressionLeftToParse = rightSideMultiplicationParseResult.1
            parsedNumber *= parsedRightNumber
        }
    
        return (parsedNumber,expressionLeftToParse)
    }

 
    private class func parse(number expression: String) -> (Int, String) {
        var parsedNumber = ""
        var expressionLeftToParse = expression
        
        for character in expressionLeftToParse.unicodeScalars {
            if CharacterSet.decimalDigits.contains(character) {
                parsedNumber += String(expressionLeftToParse.characters.first!)
                expressionLeftToParse = expressionLeftToParse.dropFirstCharacter()
            } else {
                break
            }
        }
        
        return (Int(parsedNumber)!, expressionLeftToParse)
    }

}

extension String {
    
    func dropFirstCharacter() -> String {
        let index = self.index(self.startIndex, offsetBy: 1)
        return self.substring(from: index)
    }
    
}

