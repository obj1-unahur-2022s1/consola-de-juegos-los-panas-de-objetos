import wollok.game.*
import consola.*
import bomberman.*


object barraDeEstado {
	method image() = "bman/barraEstadisticas.png"
}
// MENU

class Menu {
	var opcionSeleccionada = null

	method iniciar() {
		game.clear()
		keyboard.up().onPressDo{self.cambiarOpcionSeleccionadaA(opcionSeleccionada.opcionSuperior())}
		keyboard.down().onPressDo{self.cambiarOpcionSeleccionadaA(opcionSeleccionada.opcionInferior())}
		keyboard.enter().onPressDo{ opcionSeleccionada.seleccionar() game.sound("bman/sonido/seleccion2.mp3").play() }
		flechaMenu.position(opcionSeleccionada.posicion())
		game.addVisualIn(self,game.origin())
		game.addVisual(flechaMenu)
	}
	method cambiarOpcionSeleccionadaA(opcion) {
		opcionSeleccionada = opcion
		flechaMenu.position(opcionSeleccionada.posicion())
		game.sound("bman/sonido/seleccion.mp3").play()
	}
}

object pantallaDeInicio inherits Menu {
	method image() = "bman/menuBomberman.png"
	override method iniciar() {
		opcionSeleccionada = opcionComenzarJuego
		super()
	}
}

object pantallaDeControles inherits Menu {
	override method iniciar() {
		game.clear()
		keyboard.enter().onPressDo{ consola.iniciar() game.sound("bman/sonido/seleccion2.mp3").play() }
		game.addVisualIn(self,game.origin())
	}
	method image() = "bman/menuControles.png"
}

object pantallaDeGameOver inherits Menu {
	method image() = "bman/menuGameOver.png"
	override method iniciar() {
		opcionSeleccionada = opcionContinuar
		super()
	}
}

object opcionComenzarJuego {
	method posicion() = game.at(5,7)

	method seleccionar() {new Nivel1()}
	
	method opcionSuperior() = opcionSalir

	method opcionInferior() = opcionControles
}

object opcionControles {
	method posicion() = game.at(4,5)
	
	method seleccionar() {
		pantallaDeControles.iniciar()
	}
	
	method opcionSuperior() = opcionComenzarJuego
	
	method opcionInferior() = opcionSalir
}

object opcionSalir {
	method posicion() = game.at(5,3)

	method seleccionar() {game.schedule(100,
		{
			game.clear()
			consola.iniciar()
		}
	)}

	method opcionSuperior() = opcionControles

	method opcionInferior() = opcionComenzarJuego
}

object opcionContinuar {
	method posicion() = game.at(6,2)

	method seleccionar() {new Nivel1()}

	method opcionSuperior() = opcionMenuPrincipal

	method opcionInferior() = self.opcionSuperior()
}

object opcionMenuPrincipal {
	method posicion() = game.at(6,1)

	method seleccionar() {
		pantallaDeInicio.iniciar()
	}

	method opcionSuperior() = opcionContinuar

	method opcionInferior() = self.opcionSuperior()
}

object flechaMenu {
	var property position
	method image() = "bman/flecha.png"
}

object transicionNivelI {
	method image() = "bman/nivel1.png"
}
