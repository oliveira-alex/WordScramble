//
//  ContentView.swift
//  WordScramble
//
//  Created by Alex Oliveira on 03/12/20.
//

import SwiftUI

struct ContentView: View {
	@State private var usedWords = [String]()
	@State private var rootWord = ""
	@State private var newWord = ""
	
	@State private var errorTitle = ""
	@State private var errorMessage = ""
	@State private var showingError = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var startWithExample = false
	
	var score: Int {
		var lettersCount = 0
		
		for word in usedWords {
			lettersCount += word.count
		}
		
		return lettersCount
	}
	
	
    var body: some View {
		NavigationView {
			VStack {
				TextField("Enter your word", text: $newWord, onCommit: addNewWord)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.autocapitalization(.none)
					.padding()
                
                GeometryReader { listView in
                    let listWidth = listView.size.width
                    let listHeight = listView.size.height
                    let listMaxY = listView.frame(in: .global).maxY
                    let listMinY = listView.frame(in: .global).minY
                    
                    List(usedWords, id: \.self) { word in
                        GeometryReader { listItemView in
                            let itemMaxY = listItemView.frame(in: .global).maxY
                            let itemHeight = listItemView.size.height
                            let offScreenItemHeight = (itemMaxY > listMaxY) ? (itemMaxY - listMaxY) : 0
                            
                            let darkSchemeGreen = 0.2 + 0.8*(itemMaxY - listMinY)/(listHeight + itemHeight) // Varies between 0.2~1.0
                            let lightSchemeGreen = 1.0 - (darkSchemeGreen) // Varies between 0.8~0.0
                            
                            HStack {
                                Spacer()
                                    .frame(width: listWidth * offScreenItemHeight/itemHeight)
                                
                                Image(systemName: "\(word.count).circle")
                                    .foregroundColor(Color(red:  0.3,
                                                           green: (colorScheme == .dark) ? 2.0*darkSchemeGreen : 1.2*lightSchemeGreen,
                                                           blue: 2.0))
                                Text(word)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(word), \(word.count) letters")
                        }
                    }
                }
				
				Text("Score: \(score)")
					.font(.title)
			}
			.navigationBarTitle(rootWord)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Example") { loadExample() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Word") { restartGame() }
                }
            }
            .onAppear(perform: startWithExample ? loadExample : startGame)
			.alert(isPresented: $showingError) {
				Alert(title: Text(errorTitle), message: Text(errorMessage), dismissButton: .default(Text("OK")))
			}
		}
    }
	
	func restartGame() {
		usedWords.removeAll()
		newWord = ""
		
		startGame()
	}
	
	func addNewWord() {
		let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
		
		guard answer.count > 0 else { return }
		
		guard answer != rootWord else {
			wordError(title: "Same as start word", message: "Be more original")
			return
		}
		
		guard isOriginal(word: answer) else {
			wordError(title: "Word used already", message: "Be more original")
			return
		}
		
		guard isPossible(word: answer) else {
			wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
			return
		}
		
		guard isReal(word: answer) else {
			wordError(title: "Word not possible", message: "That isn't a real word")
			return
		}
		
		usedWords.insert(answer, at: 0)
		newWord = ""
	}
	
	func startGame() {
		if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
			if let startWords = try? String(contentsOf: startWordsURL) {
				let allWords = startWords.components(separatedBy: "\n")
				rootWord = allWords.randomElement() ?? "silkworm"
				
				return
			}
		}
		
		fatalError("Could not load start.txt from bundle.")
	}
	
	func isOriginal(word: String) -> Bool {
		!usedWords.contains(word)
	}
	
	func isPossible(word: String) -> Bool {
		var tempWord = rootWord.lowercased()
		
		for letter in word {
			if let position = tempWord.firstIndex(of: letter) {
				tempWord.remove(at: position)
			} else {
				return false
			}
		}
		
		return true
	}
	
	func isReal(word: String) -> Bool {
		guard word.count > 2 else { return false }
		
		let checker = UITextChecker()
		let range = NSRange(location: 0, length: word.utf16.count)
		let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
		
		return misspelledRange.location == NSNotFound
	}
	
	func wordError(title: String, message: String) {
		errorTitle = title
		errorMessage = message
		showingError = true
	}
    
    func loadExample() {
        usedWords.removeAll()
        newWord = ""
        rootWord = "widowing"
        usedWords = ["ding", "dong", "dig", "now", "wow", "god", "gin", "dog", "own", "dow", "down", "wig", "win", "widow", "wing", "window"]
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(startWithExample: true)
//			.environment(\.colorScheme, .dark)
    }
}
