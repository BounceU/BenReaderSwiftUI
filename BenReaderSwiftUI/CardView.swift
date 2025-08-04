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
            AsyncImage(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(Utils.getCoverURL(book.fileName)!)) { image in
                image.resizable()
            } placeholder: {
                Image("default_cover").resizable()
            }
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 5)
             
            
            Text(book.title)
                .font(.headline)
            let chapters = Utils.loadChaptersFromBook(book)
            if let lastChapter = chapters.last {
               let elapsed = book.location / Double(lastChapter.endTime) * 100.0
                Text("\(book.author) • \(String(format: "%.0f", elapsed))%")
                        .font(.subheadline)
            } else {
                Text("\(book.author)")
                    .font(.subheadline)
            }
            
        }
        
    }
}

#Preview {
    CardView(book: Book())
}
