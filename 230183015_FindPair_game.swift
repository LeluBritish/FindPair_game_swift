import SwiftUI
import UIKit

// MARK: - App entry
@main
struct FindPairApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: ViewController())
    }
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

// MARK: - Main menu
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Find pair"

        let button2 = makeButton(title: "2 x 2", size: 2)
        let button4 = makeButton(title: "4 x 4", size: 4)

        let stack = UIStackView(arrangedSubviews: [button2, button4])
        stack.axis = .vertical
        stack.spacing = 20
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.widthAnchor.constraint(equalToConstant: 200),
            stack.heightAnchor.constraint(equalToConstant: 130)
        ])
    }

    private func makeButton(title: String, size: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 28, weight: .semibold)
        button.backgroundColor = UIColor.systemGray5
        button.layer.cornerRadius = 12
        button.tag = size
        button.addTarget(self, action: #selector(sizeTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func sizeTapped(_ sender: UIButton) {
        let game = GameViewController(gridSize: sender.tag)
        navigationController?.pushViewController(game, animated: true)
    }
}

// MARK: - Game screen
class GameViewController: UIViewController {

    private let allEmojis = ["😈", "🧛", "😻", "🤖", "👻", "🐶", "🦊", "🐼",
                             "🐸", "🦁", "🐵", "🐙"]
    private let gridSize: Int

    private var cardEmojis: [String] = []
    private var buttons: [UIButton] = []
    private var openedIndexes: [Int] = []
    private var matchedIndexes = Set<Int>()

    private let winLabel = UILabel()
    private let gridContainer = UIView()
    private let restartButton = UIButton(type: .system)

    init(gridSize: Int) {
        self.gridSize = gridSize
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        startGame()
    }

    private func setupUI() {
        winLabel.text = "Победа!"
        winLabel.textColor = .green
        winLabel.font = .systemFont(ofSize: 32, weight: .medium)
        winLabel.textAlignment = .center
        winLabel.isHidden = true
        winLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(winLabel)

        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridContainer)

        restartButton.setTitle("Заново", for: .normal)
        restartButton.titleLabel?.font = .systemFont(ofSize: 20)
        restartButton.addTarget(self, action: #selector(restartTapped), for: .touchUpInside)
        restartButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(restartButton)

        let preferredWidth = gridContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        preferredWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            gridContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gridContainer.heightAnchor.constraint(equalTo: gridContainer.widthAnchor),
            gridContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 500),
            preferredWidth,

            winLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            winLabel.bottomAnchor.constraint(equalTo: gridContainer.topAnchor, constant: -24),

            restartButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            restartButton.topAnchor.constraint(equalTo: gridContainer.bottomAnchor, constant: 24)
        ])

        buildGrid()
    }

    private func buildGrid() {
        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.spacing = 10
        rowsStack.distribution = .fillEqually
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        gridContainer.addSubview(rowsStack)

        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: gridContainer.topAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: gridContainer.bottomAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: gridContainer.trailingAnchor)
        ])

        for row in 0..<gridSize {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 10
            rowStack.distribution = .fillEqually

            for column in 0..<gridSize {
                let button = UIButton(type: .system)
                button.tag = row * gridSize + column
                button.backgroundColor = UIColor.systemGray4
                button.setTitleColor(.black, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: gridSize == 2 ? 60 : 32)
                button.addTarget(self, action: #selector(cardTapped(_:)), for: .touchUpInside)
                buttons.append(button)
                rowStack.addArrangedSubview(button)
            }
            rowsStack.addArrangedSubview(rowStack)
        }
    }

    private func startGame() {
        openedIndexes.removeAll()
        matchedIndexes.removeAll()
        winLabel.isHidden = true

        let pairsCount = (gridSize * gridSize) / 2
        let chosen = Array(allEmojis.shuffled().prefix(pairsCount))
        cardEmojis = (chosen + chosen).shuffled()

        for button in buttons {
            button.setTitle("", for: .normal)
        }
    }

    @objc private func cardTapped(_ sender: UIButton) {
        let index = sender.tag
        if matchedIndexes.contains(index) || openedIndexes.contains(index) { return }

        if openedIndexes.count == 2 {
            for i in openedIndexes {
                buttons[i].setTitle("", for: .normal)
            }
            openedIndexes.removeAll()
        }

        sender.setTitle(cardEmojis[index], for: .normal)
        openedIndexes.append(index)

        if openedIndexes.count == 2 {
            let first = openedIndexes[0]
            let second = openedIndexes[1]
            if cardEmojis[first] == cardEmojis[second] {
                matchedIndexes.insert(first)
                matchedIndexes.insert(second)
                openedIndexes.removeAll()
                if matchedIndexes.count == cardEmojis.count {
                    winLabel.isHidden = false
                }
            }
        }
    }

    @objc private func restartTapped() {
        startGame()
    }
}