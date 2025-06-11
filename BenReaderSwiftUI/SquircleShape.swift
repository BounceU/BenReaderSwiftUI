//
//  SquircleShape.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/9/25.
//


import SwiftUI

struct SquircleShape: Shape {
    var curvature: CGFloat = 4
    
    func path(in rect: CGRect) -> Path {
        let a = rect.width / 2
        let b = rect.height / 2

        var path = Path()

        path.move(to: CGPoint(x: rect.midX + a, y: rect.midY))

        for angle in stride(from: 0.0, to: 360.0, by: 1.0) {
            let radians = angle * .pi / 180
            let x = pow(abs(cos(radians)), 2 / curvature) * a * sign(cos(radians))
            let y = pow(abs(sin(radians)), 2 / curvature) * b * sign(sin(radians))
            path.addLine(to: CGPoint(x: rect.midX + x, y: rect.midY + y))
        }

        path.closeSubpath()

        return path
    }

    private func sign(_ value: CGFloat) -> CGFloat {
        return value >= 0 ? 1 : -1
    }
}
