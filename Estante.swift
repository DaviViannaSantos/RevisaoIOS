import SwiftUI
import Combine

struct Livro: Identifiable {
    let id = UUID()
    var titulo: String
    var autor: String
    var paginas: Int
    var lido: Bool
}

class EstanteViewModel: ObservableObject {
    @Published var livros: [Livro] = [
        Livro(titulo: "O Hobbit", autor: "J.R.R. Tolkien", paginas: 310, lido: true),
        Livro(titulo: "1984", autor: "George Orwell", paginas: 328, lido: true),
        Livro(titulo: "Duna", autor: "Frank Herbert", paginas: 680, lido: false),
        Livro(titulo: "Dom Casmurro", autor: "Machado de Assis", paginas: 256, lido: false)
    ]
    
    var totalLidos: Int {
        livros.filter { $0.lido }.count
    }
    
    var paginasLidas: Int {
        livros.filter { $0.lido }.reduce(0) { $0 + $1.paginas }
    }
    
    func adicionar(titulo: String, autor: String, paginas: Int) {
        let novoLivro = Livro(
            titulo: titulo.trimmingCharacters(in: .whitespaces),
            autor: autor.trimmingCharacters(in: .whitespaces),
            paginas: paginas,
            lido: false
        )
        livros.append(novoLivro)
    }
    
    func apagar(id: UUID) {
        livros.removeAll { $0.id == id }
    }
    
    func definirLido(id: UUID, lido: Bool) {
        if let index = livros.firstIndex(where: { $0.id == id }) {
            livros[index].lido = lido
        }
    }
    
    func livro(por id: UUID) -> Livro? {
        livros.first(where: { $0.id == id })
    }
}

struct EstanteView: View {
    @StateObject private var viewModel = EstanteViewModel()
    @State private var abreNovoLivro = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Resumo") {
                    Text("Total de livros: \(viewModel.livros.count)")
                    Text("Livros lidos: \(viewModel.totalLidos)")
                    Text("Páginas lidas: \(viewModel.paginasLidas)")
                }
                
                Section("Estante") {
                    ForEach(viewModel.livros) { livro in
                        NavigationLink(destination: LivroDetalheView(viewModel: viewModel, id: livro.id)) {
                            VStack(alignment: .leading) {
                                Text(livro.titulo)
                                    .font(.headline)
                                Text(livro.autor)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let id = viewModel.livros[index].id
                            viewModel.apagar(id: id)
                        }
                    }
                }
            }
            .navigationTitle("Estante")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        abreNovoLivro = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $abreNovoLivro) {
                NovoLivroView(viewModel: viewModel)
            }
        }
    }
}

struct LivroDetalheView: View {
    @ObservedObject var viewModel: EstanteViewModel
    let id: UUID
    
    var livro: Livro? {
        viewModel.livro(por: id)
    }
    
    var body: some View {
        Form {
            if let livro = livro {
                LabeledContent("Autor", value: livro.autor)
                LabeledContent("Páginas", value: "\(livro.paginas)")
                
                Toggle("Lido", isOn: Binding(
                    get: { livro.lido },
                    set: { novoValor in
                        viewModel.definirLido(id: id, lido: novoValor)
                    }
                ))
            } else {
                Text("Livro não encontrado.")
            }
        }
        .navigationTitle(livro?.titulo ?? "Detalhe")
    }
}

struct NovoLivroView: View {
    @ObservedObject var viewModel: EstanteViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var titulo = ""
    @State private var autor = ""
    @State private var paginas = 100
    
    private var podeSalvar: Bool {
        !titulo.trimmingCharacters(in: .whitespaces).isEmpty &&
        !autor.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Título", text: $titulo)
                TextField("Autor", text: $autor)
                Stepper("Páginas: \(paginas)", value: $paginas, in: 1...2000)
            }
            .navigationTitle("Novo livro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        viewModel.adicionar(titulo: titulo, autor: autor, paginas: paginas)
                        dismiss()
                    }
                    .disabled(!podeSalvar)
                }
            }
        }
    }
}