import wollok.game.*
import jugador.*

// Clases abstractas
class Elemento {
	const property position
	method explotar() {}
	method chocarJugador() {}
	method cortaLaExplosion() = false
	method dibujar() {
		game.addVisual(self)
	}
}

class ElementoDinamico inherits Elemento {
	var frame = 0

	override method dibujar() {
		super()
 		jugador.refrescarFrame()
	}
	method remover() {
		game.removeVisual(self)
		game.removeTickEvent(position.toString())
	}
	
	method animar() {
		frame = (frame + 1)
	}
}

// Bloques
class Bloque inherits Elemento {
	method image() = "assets/solidBlock.png"
	override method chocarJugador() {
		jugador.retroceder()
	}
	override method explotar() {
		throw new Exception(message="El elemento no puede ser destruido")
	}
	override method cortaLaExplosion() = true
}

class BloqueVulnerable inherits Bloque {
	override method image() = "assets/explodableBlock.png"
	override method explotar() {
		game.removeVisual(self)
	}
}

// Bomba

class Bomba inherits ElementoDinamico {
	var acabaDeSerPlantada = true
	const posicionesQueExplota = [position,position.up(1),position.right(1),position.down(1),position.left(1)]
	
	override method dibujar() {
			super()
			self.aumentarAlcance()
			game.onTick(800,position.toString(),{self.animar()})
 			game.schedule(3000,{self.explotar()})
	}
 	override method explotar() {
 		if(game.hasVisual(self)) {
 			self.remover()
 			posicionesQueExplota.forEach({posicion => new Flama(position=posicion).dibujar()})
 			jugador.agregarBombaDisponible()
 		}
 	}
 	method aumentarAlcance() {
 		if(!game.getObjectsIn(position.up(1)).any({elemento => elemento.cortaLaExplosion()})) {
 			posicionesQueExplota.add(position.up(2))
 		}
 		if(!game.getObjectsIn(position.right(1)).any({elemento => elemento.cortaLaExplosion()})) {
 			posicionesQueExplota.add(position.right(2))
 		}
 		if(!game.getObjectsIn(position.down(1)).any({elemento => elemento.cortaLaExplosion()})) {
 			posicionesQueExplota.add(position.down(2))
 		}
 		if(!game.getObjectsIn(position.left(1)).any({elemento => elemento.cortaLaExplosion()})) {
 			posicionesQueExplota.add(position.left(2))
 		}
 	}
 	method image() = "assets/bomba/bomba" + frame.toString() + ".png"
 	override method animar() {
 		super()
 		frame %= 3
 	}
 	override method chocarJugador() {
 		if(not acabaDeSerPlantada) {
			jugador.retroceder()
		}
		else {
			acabaDeSerPlantada = false
		}
 	}
 }
 
 class Flama inherits ElementoDinamico {
 	override method dibujar() {
 		super()
 		game.onTick(100,position.toString(),{self.animar()})
 		game.onCollideDo(self,{elemento => self.hacerExplotar(elemento)})
 		game.schedule(2000,{self.remover()})
 	}
 	
 	method hacerExplotar(elemento) {
 		try {
 			elemento.explotar()
 		}
 		catch exception {
 			self.remover()
 		}
 	}
 	
 	override method remover() {
 		if(game.hasVisual(self)) {
 			super()
 		}
 	}

 	method image() = "assets/bomba/flama" + frame.toString() + ".png"
 	override method animar() {
 		super()
 		frame %= 5
 	}
 }
 
 