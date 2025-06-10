//
//  SelectionView.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/9/25.
//

import SwiftUI
import SwiftData

struct SelectionView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var books: [Book];
    
    var columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let height: CGFloat = 150
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(books) { book in
                        
                        NavigationLink(destination: ContentView()) {
                            CardView(book: book).frame(width: .infinity)
                            
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            
                            Button {
                                
                            } label: {
                                Label("Details", systemImage: "info.circle")
                            }
                            
                            Button(role: .destructive) {
                              
                                    //removeBook(book);
                                
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                }
                
                
                .padding()
                
            }
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Label("Books", systemImage: "book").font(.title)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Text("Books").font(.largeTitle)
                }
                
             
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            
        }
       
        
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Book()
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(books[index])
            }
        }
    }
    
    
//    func getStuffFromUser() -> Book? {
//        
//        return Book();
//    }
//    
//    func addBook() {
//        
//        if let newBook = getStuffFromUser() {
//            
//            withAnimation {
//                modelContext.insert(newBook)
//            }
//        } else {
//            
//        }
//        
//    }
//    
//    func removeBook(_ book: Book) {
//        withAnimation {
//            // Remove folder with FileManager.default.removeItem(atPath: directoryUrl)
//           
//            
//            // Remove book from defaults
//            modelContext.delete(book);
//            
//        }
//    }
//    
    func loadTextFile() {
        
        
        
    }
    
    
    
}


#Preview {
    SelectionView()
        .modelContainer(for: Book.self, inMemory: true)
}
