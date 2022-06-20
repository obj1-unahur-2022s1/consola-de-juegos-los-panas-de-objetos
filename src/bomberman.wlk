import wollok.game.*
import consola.*
import juego.*

// NIVELES

class Nivel {
	method configurar() {
		// BLOQUES
		self.ponerLimites()
		self.ponerBloquesAlternados()
	}
	method ponerLimites() {
		const ancho = game.width() - 1
		const largo = game.height() - 2
		const posiciones = []
		
		(1..ancho-1).forEach { i => posiciones.add(new Position(x=i,y=0));posiciones.add(new Position(x=i,y=largo)) }
		(0..largo).forEach { i => posiciones.add(new Position(x=0,y=i));posiciones.add(new Position(x=ancho,y=i)) }
		
		posiciones.forEach { pos => game.addVisualIn(new Bloque(),pos)}
	}
	// Dibuja matriz de bloques fijos alternados
	method ponerBloquesAlternados() {
		const ancho = game.width() - 1
		const largo = game.height() - 1
		const listaFilas = []
		const listaColumnas = []
		
		(2..largo-2).filter {numero => numero.even()}.forEach {numero => listaFilas.add(numero)}
		(2..ancho-2).filter {numero => numero.even()}.forEach {numero => listaColumnas.add(numero)}
		
		listaColumnas.forEach{columna => self.dibujarFilasBloques(listaFilas,columna)}
	}
	method dibujarFilasBloques(listaFilas,nroColumna) {
		listaFilas.forEach{nroFila => game.addVisualIn(new Bloque(),game.at(nroColumna,nroFila))}
	}
}

class Nivel1 inherits Nivel {
	override method configurar() {
		game.addVisualIn(fondoDeNivel,game.origin())
		super()
		self.configurarEscenario()
		// JUGADOR
		jugador.iniciar()
		// BICHITOS
		new Enemigo(position=game.at(5,5),direccion=oeste).dibujar()
		new Enemigo(position=game.at(1,7),direccion=oeste).dibujar()
	}
	method configurarEscenario() {
		const fila1 = [3,4,5,6,7] 		// Columnas	
		const fila2 = [3,5,11]			// bloques fijos en 2,4,6,8,10
		const fila3 = [2,3,4,5,6]
		const fila4 = [1,3,5,7,11]		// bloques fijos en 2,4,6,8,10
		const fila5 = [2,3,9]
		const fila6 = [1,3,5,7]			// bloques fijos en 2,4,6,8,10
		const fila7 = [3,7]
		const listaColumnas = [fila1,fila2,fila3,fila4,fila5,fila6,fila7]
		
		(1..7).forEach{fila => self.dibujarBloquesVulnerables(listaColumnas.get(fila-1),fila)}
	}
	method dibujarBloquesVulnerables(listaPosColumnas,posFila) {
		listaPosColumnas.forEach{posColumna => game.addVisualIn(new BloqueVulnerable(),game.at(posColumna,posFila))}
	}
}

// PERSONAJES

class Personaje {
	var position = null
	var direccion = null
	var frame = 0
	
	method mover(_direccion) {
		direccion = _direccion
		position = direccion.siguiente(position)
		self.animar()
	}
	method animar(){
		self.pasarFrame()
		game.schedule(250,{self.pasarFrame()})
	}
	method pasarFrame() {
		frame = (frame + 1) % 4
	}
	method position() = position
	method image() = direccion.toString() + frame.toString() + ".png"
}

// JUGADOR

object jugador inherits Personaje {
	var bombasDisponibles = 1
	
	method iniciar() {
		position = game.at(1,1)
		direccion = sur
		bombasDisponibles = 1
		frame = 0

		keyboard.up().onPressDo({self.mover(norte)})
		keyboard.right().onPressDo({self.mover(este)})
		keyboard.left().onPressDo({self.mover(oeste)})
		keyboard.down().onPressDo({self.mover(sur)})
		keyboard.d().onPressDo({self.plantarBomba()})
		
		game.addVisual(self)
		game.onCollideDo(self,{elemento => elemento.chocarJugador()})
	}
	
	method retroceder() { 
		position = direccion.opuesto().siguiente(position)
	}
	
	method plantarBomba() {
		if (self.puedePlantarBomba())
			new Bomba(position = position).colocar()
			bombasDisponibles -= 1
	}
	
	method explotar() {
		self.morir()
	}
	
	method morir() {
		gameOver.iniciar()
	}

	method puedePlantarBomba() = game.getObjectsIn(position).size() == 1 and bombasDisponibles > 0
	method agregarBombaDisponible() {bombasDisponibles += 1}
	
	method refrescarFrame() {
		game.removeVisual(self)
		game.addVisual(self)
	}
	
	override method image() = "bman/bman_" + super()
}

// ENEMIGOS

class Enemigo inherits Personaje {
	
	method dibujar() {
		game.addVisual(self)
		game.onTick(500,self.identity().toString(),{self.moverse()})
	}
	method explotar() {
		game.removeVisual(self)
		game.removeTickEvent(self.identity().toString().toString())
	}
	method chocarJugador() {
		jugador.morir()
	}
	method moverse() {
		if (self.puedeAvanzarHacia(direccion)) {
			self.mover(direccion)
		}
		else {
			self.cambiarDeDireccion()
		}
	}
	
	method cambiarDeDireccion() {
		const direccionesPosibles = [norte,este,sur,oeste]
		direccionesPosibles.removeAllSuchThat( {direccion => !self.puedeAvanzarHacia(direccion) })
		try {
			direccion = direccionesPosibles.anyOne()
		}
		catch e {
			direccion = direccion.opuesto()
		}
	}

	method puedeAvanzarHacia(unaDireccion) {
		const elementosEnDireccion = game.getObjectsIn(unaDireccion.siguiente(position))
		return elementosEnDireccion.isEmpty() or (elementosEnDireccion.size() == 1 and elementosEnDireccion.contains(jugador))
	}

	override method image() = "bman/bichito_" + super()
	
}

// BLOQUES

class Bloque {
	method image() = "bman/solidBlock.png"
	method explotar() {
		game.colliders(self).forEach { objeto => objeto.remover() }
	}
	method chocarJugador() {jugador.retroceder()}
}

class BloqueVulnerable inherits Bloque {
	override method image() = "bman/explodableBlock.png"
	override method explotar() {
		game.colliders(self).first().remover()
		game.removeVisual(self)
	}
}

// HABILIDAD JUGADOR

class Bomba {
	const property position
	var frame = 0
	var acabaDeSerPlantada = true
	
	method colocar() {
			game.addVisual(self)
			jugador.refrescarFrame()
			game.onTick(800,self.identity().toString(),{self.animar()})
 			game.schedule(3000,{self.explotar()})
	}
 	method explotar() {
 		if(game.hasVisual(self)) {
			game.removeVisual(self)
			game.removeTickEvent(self.identity().toString())
 			jugador.agregarBombaDisponible()
 			new Flama(position=position).dibujar()
			new Explosion(direccion=norte,position=position).desencadenar()
			new Explosion(direccion=este,position=position).desencadenar()
			new Explosion(direccion=sur,position=position).desencadenar()
			new Explosion(direccion=oeste,position=position).desencadenar()	
		}
 	}
 		
 	method image() = "bman/bomba" + frame.toString() + ".png"
 	method animar() {
 		frame = (frame + 1) % 3
 	}
 	method chocarJugador() {
 		if (acabaDeSerPlantada) {
 			acabaDeSerPlantada = false
 		}
 		else {
 			jugador.retroceder()
 		}
 	}
 }
 
class Explosion {
	const direccion
	var position
	var posicionesAlcanzadas = 0
	var alcance = 2
	method desencadenar() {
		game.addVisual(self)
		game.onTick(100,self.identity().toString(),{self.avanzar()})
	}
	method avanzar() {
		if (posicionesAlcanzadas == alcance) {
			self.remover()
		}
		else {
			position = direccion.siguiente(position)
			posicionesAlcanzadas += 1
			new Flama(position=position).dibujar()
		}
	}
	method remover() {
		game.removeVisual(self)
		game.removeTickEvent(self.identity().toString())
	}
	method explotar() {}
	method position() = position
	method image() = "bman/explosion.png"
}
 
class Flama {
	const property position
	var frame = 0
	method dibujar() {
		game.addVisual(self)
		jugador.refrescarFrame()
		game.onTick(100,self.identity().toString(),{self.animar()})
		game.onCollideDo(self,{elemento => elemento.explotar()})
		game.schedule(2000,{self.remover()})
	}
 	
	method remover() {
		if(game.hasVisual(self)) {
			game.removeVisual(self)
			game.removeTickEvent(self.identity().toString())
			jugador.agregarBombaDisponible()
		}
	}
	
	method explotar() {}
	method chocarJugador() {}

	method animar() { frame = (frame + 1) % 5 }
	method image() = "bman/flama" + frame.toString() + ".png"

}

// DIRECCIONES

object norte {
	method siguiente(posicion) = posicion.up(1)
	method opuesto() = sur
}

object este {
	method siguiente(posicion) = posicion.right(1)
	method opuesto() = oeste
}

object sur {
	method siguiente(posicion) = posicion.down(1)
	method opuesto() = norte
}

object oeste {
	method siguiente(posicion) = posicion.left(1)
	method opuesto() = este
}

// FONDO

object fondoDeNivel {
	method image() = "bman/pisoMosaico.png"
}
// PANTALLA GAME OVER

object gameOver {
	method image() = "bman/gameover-final.png"
	
	method iniciar() {
		game.clear()
		game.addVisualIn(self,game.origin())
		cursor.iniciar()
	}

	method reiniciar() {
		game.clear()
		bomberman.iniciar()
	}

	method menuInicial() {
		game.clear()
		consola.iniciar()
	}
}

object cursor {
	var opcion = 0
	const posInicial = 7
	method image() = "cursor.png"
	method position() = game.at(posInicial + opcion * 2,2)
	
	method iniciar() {
		keyboard.right().onPressDo{self.cambiarOpcion()}
		keyboard.left().onPressDo{self.cambiarOpcion()}
		keyboard.enter().onPressDo{self.accionarOpcion()}
		game.addVisual(self)
	}

	method cambiarOpcion() {
		opcion = (opcion + 1) % 2
	}
	method accionarOpcion() {
		if (opcion == 0) gameOver.reiniciar() else gameOver.menuInicial()
	}
}