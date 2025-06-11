//
//  AudioPlayerView.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/10/25.
//


import SwiftUI

struct AudioPlayerView: View {
    
    @State var isPlaying: Bool = true;
    @State var progress = 0.0
    
    var body: some View {
        
        NavigationStack {
            VStack {
                
                Spacer()
                
                
                // MARK: - Cover Image
                
                Image("default_cover")
                    .resizable()
                    .scaledToFit()
                    .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 0.0)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)
                
                
                
                
                Spacer()
                
                // MARK: - Progress Bar
                
                Slider(value: $progress, in: 0...1) .padding([.leading, .trailing], 50).controlSize(.small)
                
                HStack {
                    Text("Min")
                    Spacer()
                    Text("\(progress)");
                    Spacer()
                    Text("Max")
                }.padding([.leading, .trailing], 50);
                
                HStack {
                    
                }
                
                
                // MARK: - Audio Buttons
                
                HStack {
                    Button(action: {}) {
                        Label {
                        } icon: {
                            Image(systemName: "backward.end").resizable().scaledToFit().frame(width: 50)
                        }
                    }.buttonStyle(.plain).padding(.leading, 50)
                    
                    Button(action: {}) {
                        Label {
                        } icon: {
                            Image(systemName: "gobackward.30").resizable().scaledToFit().frame(width:50)
                        }
                    }.buttonStyle(.plain).padding()
                    
                    Button(action: {
                        self.isPlaying.toggle() ;
                    }) {
                        Label {
                        } icon: {
                            Image(systemName: isPlaying ? "play.circle.fill" :  "pause.circle.fill").resizable().scaledToFit().frame(width: 80)
                        }
                    }.buttonStyle(.plain).padding()
                    
                    Button(action: {}) {
                        Label {
                        } icon: {
                            Image(systemName: "goforward.30").resizable().scaledToFit().frame(width: 50)
                        }
                    }.buttonStyle(.plain).padding()
                    Button(action: {}) {
                        Label {
                        } icon: {
                            Image(systemName: "forward.end").resizable().scaledToFit().frame(width: 50)
                        }
                    }.buttonStyle(.plain).padding(.trailing, 50)
                }
                
                
                // MARK: - Bottom Row of Buttons
                
                Button {
                    
                } label: {
                    Label("Howdy", systemImage: "person.circle.fill");
                }
                
            }
            
            // MARK: - Navigation Title
            
            .navigationTitle(Text("Title of Book")).navigationBarTitleDisplayMode(.inline)
            
        }
        
    }
}

#Preview {
    AudioPlayerView()
}
