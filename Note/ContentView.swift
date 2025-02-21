import SwiftUI

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
    var isCompleted: Bool = false
}

class NotesViewModel: ObservableObject {
    @AppStorage("notes") private var notesData: Data?
    @Published var notes: [Note] = [] {
        didSet {
            saveNotes()
        }
    }
    
    init() {
        loadNotes()
    }
    
    func addNote(title: String, content: String) {
        let newNote = Note(title: title, content: content)
        notes.append(newNote)
    }
    
    func updateNote(id: UUID, title: String, content: String) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].title = title
            notes[index].content = content
        }
    }
    
    func toggleCompletion(for note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isCompleted.toggle()
        }
    }
    
    func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
    }
    
    private func saveNotes() {
        do {
            let encoded = try JSONEncoder().encode(notes)
            notesData = encoded
        } catch {
            print("Error. Could not save notes: \(error.localizedDescription)")
        }
    }
    
    private func loadNotes() {
        if let notesData = notesData {
            do {
                let decoded = try JSONDecoder().decode([Note].self, from: notesData)
                notes = decoded
            } catch {
                print("Error. Could not load notes: \(error.localizedDescription)")
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var showingAddNote = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.notes) { note in
                    NavigationLink(destination: NoteDetailView(viewModel: viewModel, note: note)) {
                        HStack(){
                            VStack(alignment: .leading) {
                                Text(note.title)
                                    .font(.headline)
                                    .strikethrough(note.isCompleted, color:Color.gray)
                                Text(note.content)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                .foregroundColor(.gray)}
                            Spacer()
                            if note.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)}
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteNote)
            }
            .navigationTitle("Notes")
            .toolbar {
                Button(action: { showingAddNote = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddEditNoteView(viewModel: viewModel)
            }
        }
    }
}

struct AddEditNoteView: View {
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var content = ""
    var note: Note?
    
    init(viewModel: NotesViewModel, note: Note? = nil) {
        self.viewModel = viewModel
        self.note = note
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextEditor(text: $content)
                    .frame(minHeight: 200)
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !title.isEmpty {
                            if let note = note {
                                viewModel.updateNote(id: note.id, title: title, content: content)
                            } else {
                                viewModel.addNote(title: title, content: content)
                            }
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct NoteDetailView: View {
    @ObservedObject var viewModel: NotesViewModel
    var note: Note
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(note.title).font(.largeTitle).padding()
                .strikethrough(note.isCompleted, color:Color.gray)
            Text(note.content).padding([.leading, .trailing, .bottom])
            Spacer()
            Button(action: { viewModel.toggleCompletion(for: note) }) {
                Text(note.isCompleted ? "Mark as Incomplete" : "Mark as Completed")
                    .padding()
                    .kerning(1)
                    .frame(maxWidth: .infinity)
                    .background(note.isCompleted ? Color.orange : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Note Details")
        .toolbar {
            NavigationLink(destination: AddEditNoteView(viewModel: viewModel, note: note)) {
                Image(systemName: "pencil")
            }
        }
    }
}

#Preview {
    ContentView()
}
