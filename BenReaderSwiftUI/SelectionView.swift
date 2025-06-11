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
    @Query(sort: \Book.lastOpened, order: .reverse) var books: [Book];
    @State private var showFileImporter = false
    @State private var selectedFileUrl: URL?
    
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
                        
                        NavigationLink(destination: CardView(book: book)) {
                            CardView(book: book)
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation {
                                        book.lastOpened = Date.now;
                                    }
                                })
                        }
                        
                        .buttonStyle(.plain)
                        .contextMenu {
                            
                            Button {
                                
                            } label: {
                                Label("Details", systemImage: "info.circle")
                            }
                            
                            Button(role: .destructive) {
                              
                                    removeBook(book);
                                
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
                    Button {
                        showFileImporter = true;
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                            
                }
            }
            
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.zip], allowsMultipleSelection: false) { result in
                        switch result {
                        case .success(let urls):
                            if let firstUrl = urls.first {
                                selectedFileUrl = firstUrl
                                print("Selected file URL: \(firstUrl)")
                                
                                addBook(url: firstUrl);
                            }
                        case .failure(let error):
                            print("Error importing file: \(error.localizedDescription)")
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
    
    
    func getStuffFromUser(url: URL) -> Book? {
        return Utils.processSelectedFile(url: url, books: books)

    }
    
    func addBook(url: URL) {
        
        if let newBook = getStuffFromUser(url: url) {
            
            withAnimation {
                modelContext.insert(newBook)
            }
        } else {
            print("Couldn't add book");
        }
        
    }
    
    func removeBook(_ book: Book) {
        withAnimation {
            //Remove folder
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
            let epubURL = documentsDirectory.appendingPathComponent("/\(book.fileName)");
            do {
                try FileManager.default.removeItem(at: epubURL);
            } catch {
                print("Couldn't remove book");
            }
            
            // Remove book from defaults
            modelContext.delete(book);
            
        }
    }
    
    func loadTextFile() {
        
        
        
    }
    
    
    
}


#Preview {
    SelectionView()
        .modelContainer(for: Book.self, inMemory: true)
}
