import wollok.game.*
import consola.*
import bomberman.*

class Juego {
	var property position = null
	var property color 
	
	method iniciar(){
        game.addVisual(object{method position()= game.center() method text() = "Juego "+color + " - <q> para salir"})		
	}
	
	method terminar(){

	}
	method image() = "juego" + color + ".png"
	

}

object bomberman inherits Juego(color = null) {
	override method iniciar() {
		nivel1.configurar()
	}
	method image() = "bman_head.png"
}