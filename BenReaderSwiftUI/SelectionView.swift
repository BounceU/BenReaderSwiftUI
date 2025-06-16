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
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Book.lastOpened, order: .reverse) var books: [Book];
    @State private var showFileImporter: Bool = false
    @State var selectedFileUrl: URL?
    
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
                        
                        NavigationLink(destination: AudioPlayerView(book: book).tint(.primary).navigationBarBackButtonHidden(true).toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    dismiss() // Dismiss the view
                                } label: {
                                    ZStack {
                                        Image(systemName: "chevron.backward.circle.fill").resizable().frame(width: 30, height: 30)
                                            .foregroundStyle(.primary)
                                        
                                       
                                    }
                                }.buttonStyle(.plain).padding()
                            }
                        }) {
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
                        Label("Add Item", systemImage: (selectedFileUrl != nil) ? "progress.indicator" : "plus" ).onChange(of: selectedFileUrl) { oldVal, newVal in
                            if(newVal == nil) {
                                
                            } else {
                                addBook()
                            }
                        }
                    }
                            
                }
            }.tint(.primary)
            
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.zip], allowsMultipleSelection: false) { result in
                        switch result {
                        case .success(let urls):
                            
                           
                            if let firstUrl = urls.first {
                                
                                
                                selectedFileUrl = firstUrl
                               
                                //addBook(url: firstUrl);
                              
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
    
    func addBook() {
        let url = selectedFileUrl!
        if let newBook = getStuffFromUser(url: url) {
            withAnimation {
                modelContext.insert(newBook)
                selectedFileUrl = nil;
            }
        } else {
            print("Couldn't add book");
        }
        
    }
    
    func removeBook(_ book: Book) {
        //Remove folder
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
        let epubURL = documentsDirectory.appendingPathComponent("/\(book.fileName)");
        do {
            try FileManager.default.removeItem(at: epubURL);
        } catch {
            print("Couldn't remove book");
        }
        
        withAnimation {
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
