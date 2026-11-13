import SwiftUI
import Combine

struct EquipeLab: Identifiable {
    let id = UUID()
    var nome: String
    var tema: String
    var integrantes: Int
}

class LaboratorioViewModel: ObservableObject {
    @Published var equipes: [EquipeLab] = [
        EquipeLab(nome: "Alpha", tema: "Inteligência Artificial", integrantes: 4),
        EquipeLab(nome: "Beta", tema: "Desenvolvimento Mobile", integrantes: 3),
        EquipeLab(nome: "Gamma", tema: "Sistemas Distribuídos", integrantes: 5),
        EquipeLab(nome: "Delta", tema: "Segurança da Informação", integrantes: 2)
    ]
    @Published var aviso: String = ""
    
    var totalIntegrantes: Int {
        equipes.reduce(0) { $0 + $1.integrantes }
    }
    
    func apagar(id: UUID) {
        equipes.removeAll { $0.id == id }
    }
    
    func definirIntegrantes(id: UUID, valor: Int) {
        if let index = equipes.firstIndex(where: { $0.id == id }) {
            equipes[index].integrantes = valor
        }
    }
    
    func publicarAviso(_ novoAviso: String) {
        aviso = novoAviso.trimmingCharacters(in: .whitespaces)
    }
    
    func equipe(por id: UUID) -> EquipeLab? {
        equipes.first(where: { $0.id == id })
    }
}

struct LaboratorioView: View {
    @StateObject private var viewModel = LaboratorioViewModel()
    
    var body: some View {
        TabView {
            EquipesTabView(viewModel: viewModel)
                .tabItem {
                    Label("Equipes", systemImage: "person.3")
                }
            
            AvisoTabView(viewModel: viewModel)
                .tabItem {
                    Label("Aviso", systemImage: "megaphone")
                }
        }
    }
}

struct EquipesTabView: View {
    @ObservedObject var viewModel: LaboratorioViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Text("Integrantes: \(viewModel.totalIntegrantes)")
                    .font(.headline)
                
                ForEach(viewModel.equipes) { equipe in
                    NavigationLink(destination: EquipeDetalheView(viewModel: viewModel, id: equipe.id)) {
                        VStack(alignment: .leading) {
                            Text(equipe.nome)
                                .font(.headline)
                            Text(equipe.tema)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let id = viewModel.equipes[index].id
                        viewModel.apagar(id: id)
                    }
                }
            }
            .navigationTitle("Equipes")
        }
    }
}

struct EquipeDetalheView: View {
    @ObservedObject var viewModel: LaboratorioViewModel
    let id: UUID
    
    var equipe: EquipeLab? {
        viewModel.equipe(por: id)
    }
    
    var body: some View {
        Form {
            if let equipe = equipe {
                LabeledContent("Tema", value: equipe.tema)
                
                Stepper(
                    "Integrantes: \(equipe.integrantes)",
                    value: Binding(
                        get: { equipe.integrantes },
                        set: { novoValor in
                            viewModel.definirIntegrantes(id: id, valor: novoValor)
                        }
                    ),
                    in: 1...12
                )
            } else {
                Text("Equipe não encontrada.")
            }
        }
        .navigationTitle(equipe?.nome ?? "Detalhe")
    }
}

struct AvisoTabView: View {
    @ObservedObject var viewModel: LaboratorioViewModel
    @State private var abreNovoAviso = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(viewModel.aviso.isEmpty ? "Nenhum aviso" : viewModel.aviso)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Novo aviso") {
                    abreNovoAviso = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Aviso")
            .sheet(isPresented: $abreNovoAviso) {
                NovoAvisoView(viewModel: viewModel)
            }
        }
    }
}

struct NovoAvisoView: View {
    @ObservedObject var viewModel: LaboratorioViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var rascunhoAviso = ""
    
    private var podePublicar: Bool {
        !rascunhoAviso.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Aviso", text: $rascunhoAviso)
                .textFieldStyle(.roundedBorder)
            
            Button("Publicar") {
                viewModel.publicarAviso(rascunhoAviso)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!podePublicar)
            
            Spacer()
        }
        .padding()
    }
}