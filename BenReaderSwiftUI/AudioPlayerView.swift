//
//  AudioPlayerView.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/10/25.
//


import SwiftUI
import AVFAudio
import MediaPlayer
import WebKit
import SwiftData

struct AudioPlayerView: View {
    
    @Environment(\.self) var environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State var isPlaying: Bool = true;
    @State var progress: Double = 0.0
    @State var currentChapter: Chapter;
    @State var remainingDuration: Double = 0.0;
    @State var showChapters: Bool = false;
    @State var showSpeeds: Bool = false;
    @State var showTimers: Bool = false;
    @State var showText: Bool = false;
    @State var shouldScroll: Bool = true;
    @State var cursorOffset: Int = 0;
    @State var currentParagraph: Int = -1;
    
    @State var timerValue: TimeInterval?;
    
    @State var webCoord: WebCoordinator = WebCoordinator();
    
    
    @ObservedObject var player = AudioManager.shared;
    
    let timings: [Int] = [0, 8, 15, 30, 45, 60]
    
    var minValue: Double = 0.0;
    var maxValue: Double = 1.0;
    var formatter: DateComponentsFormatter;
    var otherFormatter: DateComponentsFormatter;
    
    
    @State var showStyles: Bool = false;
    @State var showSpacing: Bool = false;
    @State var showSizes: Bool = false;
    @ObservedObject var book: Book;
    @State var timeObserver: Any?;
    
    
    init(book: Book) {
        self.book = book;
        self.currentChapter = Chapter(title: "Chapter 1", startTime: "c 0:00:00".replacingOccurrences(of: "c ", with: ""), endTime: "c 0:28:20.825000".replacingOccurrences(of: "c ", with: ""));
        
        self.formatter = DateComponentsFormatter();
        self.otherFormatter = DateComponentsFormatter();
        self.minValue = currentChapter.startTime;
        self.maxValue = currentChapter.endTime;
        
        
        formatter.allowedUnits = [ .minute, .second, .nanosecond]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        otherFormatter.allowedUnits = [ .hour, .minute];
        otherFormatter.unitsStyle = .abbreviated;
        otherFormatter.zeroFormattingBehavior = .default;
        
        
    }
    
    var body: some View {
        
        
        NavigationStack {
            VStack {
                
                let style = ReaderStyle.getSharedInstance(modelContext: modelContext)
                
                if(showText) {
                    
                    WebView(url: Utils.getChapterURL(book, currentChapter)!, colors: [style.backgroundColor.toHexString(), style.textColor.toHexString()], highlightColor: style.hilightColor, fontSize: style.fontSize, spacing: style.spacing, sides: style.sides, webCoord: webCoord ).ignoresSafeArea().navigationTitle("").mask(LinearGradient(gradient: Gradient(colors: [ .clear, .black, .black, .black, .black, .black, .black, .black, .black, .clear]), startPoint: .top, endPoint: .bottom).ignoresSafeArea())
                    
                    
                } else {
                    
                    Spacer()
                    
                    // MARK: - Sleep Timer Label
                    
                    if let timerSeconds = player.timerValue {
                        HStack {
                            Spacer()
                            Text("Sleep Timer: \(formatter.string(from: .init(TimeInterval(timerSeconds - Date().timeIntervalSince1970) > 0 ? timerSeconds - Date().timeIntervalSince1970 : 0)) ?? "0 s")")
                            Spacer()
                        }
                    }
                    
                    Spacer()
                    
                    
                    
                    // MARK: - Cover Image
                    
                    AsyncImage(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(book.image)) { image in
                        image.resizable()
                    } placeholder: {
                        Image("default_cover").resizable().opacity(0)
                    }
                    .scaledToFit()
                    .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 0.0)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .secondary.opacity(0.5), radius: 5)
                    
                    
                    Spacer()
                    
                    Button(action: {
                        showChapters.toggle()
                    }) {
                        Label {
                            Text("\($currentChapter.title.wrappedValue)")
                        } icon: {
                            Image(systemName: "list.bullet")
                        }
                    }.buttonStyle(.plain)
                        .sheet(isPresented: $showChapters) {
                            
                            Text("Chapters").font(.headline).padding()
                            
                            ScrollView {
                                VStack {
                                    ForEach(0..<player.chapters.count, id: \.self) { chapter in
                                        
                                        Button(action: {
                                            player.player?.seek(to: .init(seconds: player.chapters[chapter].startTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero);
                                            player.play()
                                            showChapters = false;
                                            
                                        }) {
                                            
                                            Text("\(player.chapters[chapter].title)")
                                            Spacer()
                                            Text("\(self.otherFormatter.string(from: .init((player.chapters[chapter].endTime - player.chapters[chapter].startTime) / Double(book.rate))) ?? "")").foregroundStyle(.secondary)
                                        }.buttonStyle(.plain).padding()
                                        Divider()
                                    }
                                }
                                
                                //                                .presentationDetents([.medium])
                                //                                .presentationDragIndicator(.visible)
                            }
                        }
                    
                    Spacer()
                }
                // MARK: - Progress Bar
                
                
                
                Slider(value: $progress, in: $currentChapter.startTime.wrappedValue...$currentChapter.endTime.wrappedValue, onEditingChanged: {
                    (scrubStarted) in
                    if scrubStarted {
                        self.player.scrubState = .scrubStarted
                    } else {
                        self.player.scrubState = .scrubEnded(progress)
                    }
                }) .padding([.leading, .trailing], showText ? 30 : 50).shadow(color: .secondary, radius: 5).controlSize(.small).tint(.primary)
                
                
                if(!showText) {
                    HStack {
                        Text("\(formatter.string(from: ($progress.wrappedValue - $currentChapter.startTime.wrappedValue) / Double(book.rate)) ?? "unable to parse")")
                        Spacer()
                        Text("\(otherFormatter.string(from: TimeInterval(($remainingDuration.wrappedValue) / Double(book.rate))) ?? "Unable to Parse") left");
                        Spacer()
                        Text("- \(formatter.string(from: ($currentChapter.endTime.wrappedValue - $progress.wrappedValue) / Double(book.rate)) ?? "unable to parse")")
                    }.padding([.leading, .trailing], 50);
                    
                    
                    Spacer()
                }
                // MARK: - Audio Buttons
                
                HStack {
                    Button(action: {
                        player.prevChapter()
                    }) {
                        Label {
                        } icon: {
                            Image(systemName: "backward.end").resizable().scaledToFit().frame(width: showText ? 20 : 40)
                        }
                    }.buttonStyle(.plain).padding(.leading, showText ? 30 : 50 )
                    
                    Button(action: {
                        
                        player.skip(-30);
                    }) {
                        Label {
                        } icon: {
                            Image(systemName: "gobackward.30").resizable().scaledToFit().frame(width: showText ? 30 : 50)
                        }
                    }.buttonStyle(.plain).padding()
                    
                    Button(action: {
                        player.togglePlayer()
                        isPlaying = player.getIsPlaying();
                    }) {
                        Label {
                        } icon: {
                            Image(systemName: player.getIsPlaying() ? "pause.circle.fill" :  "play.circle.fill").resizable().scaledToFit().frame(width: showText ? 50 : 80)
                        }
                    }.buttonStyle(.plain).padding()
                    
                    Button(action: {
                        
                        player.skip(30);
                        
                    }) {
                        Label {
                        } icon: {
                            Image(systemName: "goforward.30").resizable().scaledToFit().frame(width: showText ? 30 : 50)
                        }
                    }.buttonStyle(.plain).padding()
                    Button(action: {
                        player.nextChapter()
                    }) {
                        Label {
                        } icon: {
                            Image(systemName: "forward.end").resizable().scaledToFit().frame(width: showText ? 20 : 40)
                        }
                    }.buttonStyle(.plain).padding(.trailing, showText ? 30 : 50)
                }
                
                
                // MARK: - Bottom Row of Buttons
                HStack {
                    
                    Spacer()
                    
                    // MARK: - Speeds List
                    
                    Button (action: {
                        showSpeeds.toggle()
                    }) {
                        VStack {
                            Text("\(String(format: "%.1f", book.rate))x")
                                .font(.title2) // Use a large font size like .largeTitle or .title
                                .fontWeight(.bold)
                            Text("Speed")
                        }
                    }.buttonStyle(.plain).padding().controlSize(showText ? .small : .regular)
                        .sheet(isPresented: $showSpeeds) {
                            
                            Text("Speed").font(.headline).padding()
                            ScrollView {
                                VStack {
                                    ForEach(5...30, id: \.self) { speed in
                                        
                                        Button(action: {
                                            if let audioPlayer = player.player {
                                                book.rate = Float(speed) / 10.0
                                                audioPlayer.rate = Float(speed) / 10.0
                                            } else {
                                                
                                            }
                                            showSpeeds = false;
                                            
                                        }) {
                                            
                                            Text("\(String(format: "%.1f", Double(speed) / 10.0))x")
                                            Spacer()
                                            Text("Speed").foregroundStyle(.secondary)
                                            
                                        }.buttonStyle(.plain).padding()
                                        Divider()
                                    }
                                }
                                //                            .presentationDetents([.medium])
                                //                            .presentationDragIndicator(.visible)
                            }
                        }
                    
                    Spacer()
                    
                    // MARK: - Show Text Button
                    Button(action: {
                        showText.toggle();
                        print(currentChapter.chapterPath)
                    }) {
                        VStack {
                            Image(systemName:"text.page")
                            Text("Show Text")
                        }
                    }.buttonStyle(.plain).padding().controlSize(showText ? .small : .regular)
                    
                    
                    Spacer()
                    
                    
                    // MARK: - Sleep Timer List
                    Button (action: {
                        showTimers.toggle()
                    }) {
                        VStack {
                            Image(systemName:"timer")
                            Text("Timer")
                        }
                    }.buttonStyle(.plain).padding().controlSize(showText ? .small : .regular)
                        .sheet(isPresented: $showTimers) {
                            
                            Text("Timer").font(.headline).padding()
                            ScrollView {
                                VStack {
                                    ForEach(0...12, id: \.self) { time in
                                        //
                                        Button(action: {
                                            if(time != 0) {
                                                if player.player != nil {
                                                    
                                                    player.timerValue = TimeInterval(Date().timeIntervalSince1970 + Double(time) * 60.0 * 10.0)
                                                    
                                                } else {
                                                }
                                            } else {
                                                player.timerValue = nil
                                            }
                                            player.play()
                                            showTimers = false;
                                            
                                        }) {
                                            
                                            Text("\(time == 0 ? "Off" : "\(time * 10) minutes")")
                                            Spacer()
                                            
                                        }.buttonStyle(.plain).padding()
                                        Divider()
                                    }
                                }
                                //                            .presentationDetents([.medium])
                                //                            .presentationDragIndicator(.visible)
                            }
                        }
                    
                    Spacer()
                } .toolbar {
                    // MARK: - Toolbar
                    // MARK: - Back Button to Selection View
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss() // Dismiss the view
                        } label: {
                            ZStack {
                                Image(systemName: "chevron.backward.circle.fill").resizable().frame(width: 30, height: 30)
                                    .foregroundStyle(showText ? Color(.displayP3, red: style.textColor.red, green: style.textColor.green, blue: style.textColor.blue, opacity: style.textColor.alpha) : .primary)
                                
                                
                            }
                        }.buttonStyle(.plain).padding()
                    }
                    
                    
                    // MARK: - Menu Button
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                shouldScroll.toggle();
                            } label: {
                                Label("Auto Scroll", systemImage: "lines.measurement.vertical")
                            }
                            
                            
                            
                            // MARK: - Style
                            Button {
                                withAnimation {
                                    showStyles.toggle();
                                }
                            } label: {
                                HStack {
                                    Text("Styles")
                                    Spacer()
                                    Image(systemName: showStyles ? "chevron.down" : "chevron.right")
                                }
                            }.menuActionDismissBehavior(.disabled)
                            Section(isExpanded: $showStyles, content: {
                                Button {
                                    style.light()
                                    if let web = webCoord.webview {
                                        web.evaluateJavaScript(style.getJS());
                                        currentParagraph = 0;
                                    }
                                } label: {
                                    Text("Light")
                                }.menuActionDismissBehavior(.disabled)
                                Button {
                                    style.dark()
                                    if let web = webCoord.webview {
                                        web.evaluateJavaScript(style.getJS());
                                        currentParagraph = 0;
                                    }
                                } label: {
                                    Text("Dark")
                                }.menuActionDismissBehavior(.disabled)
                                Button {
                                    style.sepia()
                                    if let web = webCoord.webview {
                                        web.evaluateJavaScript(style.getJS());
                                        currentParagraph = 0;
                                    }
                                } label: {
                                    Text("Sepia")
                                }.menuActionDismissBehavior(.disabled)
                            }, header: {
                            })
                            
                            // MARK: - Spacing
                            Button {
                                withAnimation {
                                    showSpacing.toggle();
                                }
                            } label: {
                                HStack {
                                    Text("Spacing")
                                    Spacer()
                                    Image(systemName: showSpacing ? "chevron.down" : "chevron.right")
                                }
                            }.menuActionDismissBehavior(.disabled)
                            Section(isExpanded: $showSpacing, content: {
                                Button {
                                    style.wide()
                                    if let web = webCoord.webview {
                                        web.evaluateJavaScript(style.getJS());
                                        currentParagraph = 0;
                                    }
                                } label: {
                                    Text("Wide")
                                }.menuActionDismissBehavior(.disabled)
                                Button {
                                    style.normalSpacing()
                                    if let web = webCoord.webview {
                                        web.evaluateJavaScript(style.getJS());
                                        currentParagraph = 0;
                                    }
                                } label: {
                                    Text("Normal")
                                }.menuActionDismissBehavior(.disabled)
                                Button {
                                    style.compact()
                                    if let web = webCoord.webview {
                                        web.evaluateJavaScript(style.getJS());
                                        currentParagraph = 0;
                                    }
                                } label: {
                                    Text("Compact")
                                }.menuActionDismissBehavior(.disabled)
                                
                            }, header: {
                            })
                            
                            // MARK: - Size
                            Button {
                                withAnimation {
                                    showSizes.toggle();
                                }
                            } label: {
                                HStack {
                                    Text("Sizes")
                                    Spacer()
                                    Image(systemName: showSizes ? "chevron.down" : "chevron.right")
                                }
                            }.menuActionDismissBehavior(.disabled)
                            Section(isExpanded: $showSizes, content: {
                                Button {
                                    style.small()
                                    if let web = webCoord.webview {
                                        web.evaluateJavaScript(style.getJS());
                                        currentParagraph = 0;
                                    }
                                } label: {
                                    Text("Small")
                                }.menuActionDismissBehavior(.disabled)
                                Button {
                                    style.normalSize()
                                    if let web = webCoord.webview {
                                        web.evaluateJavaScript(style.getJS());
                                        currentParagraph = 0;
                                    }
                                } label: {
                                    Text("Normal")
                                }.menuActionDismissBehavior(.disabled)
                                Button {
                                    style.largeSize()
                                    if let web = webCoord.webview {
                                        web.evaluateJavaScript(style.getJS());
                                        currentParagraph = 0;
                                    }
                                } label: {
                                    Text("Large")
                                }.menuActionDismissBehavior(.disabled)
                                Button {
                                    style.giantSize()
                                    if let web = webCoord.webview {
                                        web.evaluateJavaScript(style.getJS());
                                        currentParagraph = 0;
                                    }
                                } label: {
                                    Text("Very Large")
                                }.menuActionDismissBehavior(.disabled)
                                
                            }, header: {})
                            // MARK: - Cursor Offset
                            ControlGroup {
                                Button {
                                    cursorOffset -= 1;
                                } label: {
                                    Label("Cursor Offset", systemImage: "minus")
                                }.menuActionDismissBehavior(.disabled)
                                
                                Button {
                                    cursorOffset += 1;
                                } label: {
                                    Label("Cursor Offset", systemImage: "plus")
                                }.menuActionDismissBehavior(.disabled)
                            }
                        } label: {
                            Image(systemName: "line.horizontal.3.circle.fill").resizable().frame(width: 30, height: 30).foregroundStyle(showText ? Color(.displayP3, red: style.textColor.red, green: style.textColor.green, blue: style.textColor.blue, opacity: style.textColor.alpha) : .primary)
                            
                            
                            
                        }.listStyle(.sidebar)
                    }
                }
                
            }
            
            // MARK: - Navigation Title
            
            .navigationTitle(Text("\(book.title)")).navigationBarTitleDisplayMode(.inline)
            
            .background {
                AsyncImage(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(book.image)) { image in
                    image.resizable()
                } placeholder: {
                    Image("default_cover").resizable().opacity(0)
                }.scaledToFit().blur(radius: 80).opacity(0.9)
            }
            .tint(.primary)
        }
        .onAppear {
            
            setupRemoteControls()
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default);
                try AVAudioSession.sharedInstance().setActive(true);
            } catch {
                print(error)
            }
            
            if(timeObserver == nil) {
                addPeriodicTimeObserver()
            }
            
        }
        .onDisappear() {
        }
    }
    
    
    
    // MARK: - Time Observer for Progress Bar
    
    func addPeriodicTimeObserver() {
        // Invoke callback every half second
        let interval = CMTime(seconds: 0.5,
                              preferredTimescale: CMTimeScale(MSEC_PER_SEC))
        // Add time observer. Invoke closure on the main queue.
        timeObserver =
        player.player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
            time in
            
            switch(player.scrubState) {
            case .reset:
                progress = time.seconds
                break;
            case .scrubStarted:
                break;
            case .scrubEnded(_):
                break;
            }
            
            if let playerSecs = player.player?.currentItem?.duration.seconds {
                if(playerSecs.isNaN) {
                    remainingDuration = 0
                } else {
                    remainingDuration = playerSecs - time.seconds
                }
            } else {
                remainingDuration = 0
            }
            player.trackUpdate();
            isPlaying = player.getIsPlaying()
            book.location = time.seconds
            
            
            if let playerChap = player.currentChapter {
                if currentChapter.startTime != playerChap.startTime {
                    cursorOffset = 0
                }
            }
            currentChapter = player.currentChapter ?? self.currentChapter
            
            let thisParagraphNumber = currentChapter.getParagraphNumber(time.seconds);
            if(currentParagraph != thisParagraphNumber) {
                currentParagraph = thisParagraphNumber
                if let web = webCoord.webview {
                    web.evaluateJavaScript(" resetBody();");
                    web.evaluateJavaScript(" highlightNthSentence(\(currentParagraph + cursorOffset));");
                    
                    if(shouldScroll) {
                        web.evaluateJavaScript(" scrollToClass(\"highlight\");");
                    }
                    
                }
                
            }
            
            
        }
        
        
    }
    
    
    // MARK: - Remote Controls
    
    private func setupRemoteControls() {
        player.play(book: book);
        self.currentChapter = player.currentChapter ?? self.currentChapter
        
        
        
        let commands = MPRemoteCommandCenter.shared();
        commands.skipForwardCommand.isEnabled = true
        commands.skipBackwardCommand.isEnabled = true
        commands.skipForwardCommand.preferredIntervals = [30]
        commands.skipBackwardCommand.preferredIntervals = [30]
        commands.pauseCommand.addTarget { _ in
            player.pause();
            return .success
        }
        
        commands.playCommand.addTarget { _ in
            player.play()
            return .success
        }
        commands.nextTrackCommand.addTarget { _ in
            player.nextChapter()
            return .success
        }
        commands.previousTrackCommand.addTarget { _ in
            player.prevChapter()
            return .success
        }
        
        commands.skipForwardCommand.addTarget { _ in
            player.skip(30)
            return .success
        }
        
        commands.skipBackwardCommand.addTarget { _ in
            player.skip(-30)
            return .success
        }
        
        
        
    }
    func updateAllInfo() {
        
    }
    
    
}

extension UIColor {
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
    }
}

#Preview {
    AudioPlayerView(book: Book())
}
