//
//  CardView.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/9/25.
//

import SwiftUI

struct CardView: View {
    let book: Book
    var body: some View {
        VStack {
            Image(book.image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 5)
            
            Text(book.title)
                .font(.headline)
            Text(book.author)
                .font(.subheadline)
        }
        
    }
}

#Preview {
    CardView(book: Book())
}
