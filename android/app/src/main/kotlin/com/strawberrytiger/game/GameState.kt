package com.strawberrytiger.game

enum class GameState {
    MENU, PLAYING, GAME_OVER
}

data class Tiger(
    var x: Float,
    var y: Float,
    var width: Float,
    var height: Float,
    var velocityY: Float,
    var isOnGround: Boolean,
    var groundY: Float
)

data class Strawberry(
    var x: Float,
    var y: Float,
    var radius: Float,
    var isGolden: Boolean,
    var collected: Boolean
)

data class Rock(
    var x: Float,
    var y: Float,
    var width: Float,
    var height: Float
)

data class Cloud(
    var x: Float,
    var y: Float,
    var width: Float,
    var height: Float,
    var speed: Float
)

data class ScoreParticle(
    var x: Float,
    var y: Float,
    var text: String,
    var color: Int,
    var life: Float,
    var velocityY: Float
)
