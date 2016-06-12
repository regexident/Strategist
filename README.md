![Logo](Jumbotron.png)

# Strategist

**Strategist** provides algorithms for building strong immutable AIs for round-based games.

## Provided Algorithms:

- **Minimax** Tree Search (with alpha-beta pruning)
- **Negamax** Tree Search (with alpha-beta pruning)
- **Monte Carlo** Tree Search

## Example usage

#### Tic Tac Toe (Minimax Tree Search)

```swift
typealias Game = TicTacToeGame
typealias Player = TicTacToePlayer
typealias Policy = SimpleTreeSearchPolicy<Game>
typealias Strategy = MiniMaxTreeSearch<Game, Policy>

let players: [Player] = [.X, .O] // => [Human, Ai]
var game = Game(players: players)
let policy = Policy(maxMoves: 10, maxExplorationDepth: 10)
let strategy = Strategy(policy: policy)
while !game.evaluate().isFinal {
    let move: TicTacToeMove
    if game.currentPlayer == .White {
        move = askAndWaitForHumanPlayersMove(game.currentPlayer)
    } else {
        move = strategy.randomMaximizingMove(game)!
    }
    game = game.update(move) // moves turn and game state forward
}
print("Game ended with \(game.currentPlayer)'s \(game.evaluate()).")
```

#### Chess (Monte Carlo Tree Search)

```swift
typealias Game = ChessGame
typealias Heuristic = UpperConfidenceBoundHeuristic<Game>
typealias Policy = SimpleMonteCarloTreeSearchPolicy<Game, Heuristic>
typealias Strategy = MonteCarloTreeSearch<Game, Policy>

let players: [Player] = [.White, .Black] // => [Human, Ai]
var game = Game(players: players)
let heuristic = Heuristic(c: sqrt(2.0))
let policy = Policy(
    maxMoves: 100,
    maxExplorationDepth: 10,
    maxSimulationDepth: 10,
    simulations: 100,
    pruningThreshold: 1000,
    scoringHeuristic: heuristic
)
var strategy = Strategy(
    game: game,
    player: players[0],
    policy: policy
)
while !game.evaluate().isFinal {
    let move: ChessMove
    if game.currentPlayer == .White {
        move = askAndWaitForHumanPlayersMove(game.currentPlayer)
    } else {
        while stillPlentyOfTime() {
            strategy = strategy.refine()
        }
        move = strategy.randomMaximizingMove(game)!
    }
    strategy = strategy.update(move)
    game = game.update(move)
}    
print("Game ended with \(game.currentPlayer)'s \(game.evaluate()).")
```

## Documentation

Online API documentation can be found here [here](https://regexident.github.io/Strategist/).

## Installation

### Swift Package Manager

    .Package(url: "https://github.com/regexident/Strategist.git")

### Carthage ([site](https://github.com/Carthage/Carthage))

    github 'regexident/Strategist'

### CocoaPods ([site](http://cocoapods.org/))

    pod 'Strategist'
    
## License

**Strategist** is available under the [**MPL-2.0**](https://www.mozilla.org/en-US/MPL/2.0/) ([tl;dr](https://tldrlegal.com/license/mozilla-public-license-2.0-(mpl-2))) license (see `LICENSE` file).
