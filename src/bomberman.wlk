import wollok.game.*

// direcciones
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

object background {
	method explotar() {}
	method chocarConJugador() {}
	method image() = "bman/fondo.png"
	method initialize() {
		game.addVisualIn(self,game.at(0,0))
	}
}

class Nivel {
	method configurar() {
		// BLOQUES
		self.ponerLimites()
		self.dibujarBloquesFijos([2,4,6],[2,4,6,8,10])
	}
	method ponerLimites() {
		const ancho = game.width() - 1
		const largo = game.height() - 1
		const posiciones = []
		
		(1..ancho-1).forEach { i => posiciones.add(new Position(x=i,y=0));posiciones.add(new Position(x=i,y=largo)) }
		(0..largo).forEach { i => posiciones.add(new Position(x=0,y=i));posiciones.add(new Position(x=ancho,y=i)) }
		
		posiciones.forEach { pos => new Bloque(position = pos).dibujar() }
	}
	// Dibuja matriz de bloques fijos
	method dibujarBloquesFijos(listaFilas,listaColumnas) {
		listaColumnas.forEach{columna => self.dibujarFilasBloques(listaFilas,columna)}
	}
	method dibujarFilasBloques(listaFilas,nroColumna) {
		listaFilas.forEach{nroFila => new Bloque(position = game.at(nroColumna,nroFila)).dibujar()}
	}
	method hayUnBloqueEn(posicion) {
		return game.getObjectsIn(posicion).any { elemento => elemento.kindName() == 'a Bloque' or elemento.kindName() == 'a BloqueVulnerable'}
	}
}

object nivel1 inherits Nivel {
	override method configurar() {
		super()
		self.configurarEscenario()
		// JUGADOR
		jugador.iniciar()
		// BICHITOS
		new Enemigo(id=1,position=game.at(5,5)).dibujar()
		new Enemigo(id=2,position=game.at(1,7)).dibujar()
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
		listaPosColumnas.forEach{posColumna => new BloqueVulnerable(position = game.at(posColumna,posFila)).dibujar()}
	}
}

object jugador {
	var position = game.at(1,1)
	var direccion = sur
	var estaVivo = true
	var bombasDisponibles = 3
	var frame = 0
	
	method iniciar() {
		game.addVisual(self)
		// TECLADO
		keyboard.up().onPressDo({self.mover(norte)})
		keyboard.right().onPressDo({self.mover(este)})
		keyboard.left().onPressDo({self.mover(oeste)})
		keyboard.down().onPressDo({self.mover(sur)})
		keyboard.d().onPressDo({self.plantarBomba()})
		// COLISIONES
		game.onCollideDo(self,{elemento => elemento.chocarJugador()})
	}
	// movimientos
	method mover(_direccion) {
		if (estaVivo) {
			direccion = _direccion
			self.avanzar(_direccion)
		}
	}
	method avanzar(_direccion) {
		position = direccion.siguiente(position)
		self.animar()
	}
	method retroceder() { 
		position = direccion.opuesto().siguiente(position)
	}
	// otras acciones
	
	method plantarBomba() {
		if (self.puedePlantarBomba())
			new Bomba(position = position).dibujar()
			bombasDisponibles -= 1
		}
	
	method explotar() {
		self.morir()
		
	}
	
	method morir() {
		estaVivo = false
		game.removeVisual(self)
	}
	// estado
	method puedePlantarBomba() = game.getObjectsIn(position).size() == 1 and bombasDisponibles > 0 and estaVivo
	method agregarBombaDisponible() {bombasDisponibles += 1}
	
	method cortaLaExplosion() = false
	// animaciones
	method animar(){
		self.pasarFrame()
		game.schedule(250,{self.pasarFrame()})
	}
	method pasarFrame() {
		frame = (frame + 1) % 4
	}
	method refrescarFrame() {
		game.removeVisual(self)
		game.addVisual(self)
	}
	// getters visual
	method position() = position
	method image() = "bman/bman_" + direccion.toString() + frame.toString() + ".png"
}

class Enemigo {
	var property position
	const id
	var frame = 0
	var direccionDondeApunta = oeste
	
	method cortaLaExplosion() = false
	method dibujar() {
		game.addVisual(self)
		game.onTick(500,id.toString(),{self.moverse()})
	}
	method explotar() {
		game.removeVisual(self)
		game.removeTickEvent(id.toString())
	}
	method chocarJugador() {
		jugador.morir()
	}
	method moverse() {
		if (self.puedeAvanzarHacia(direccionDondeApunta)) {
			position = direccionDondeApunta.siguiente(position)
			self.pasarFrame()
		}
		else {
			self.cambiarDeDireccion()
		}
	}
	
	method cambiarDeDireccion() {
		const direcciones = [norte,este,sur,oeste]
		direcciones.removeAllSuchThat( {direccion => !self.puedeAvanzarHacia(direccion) })
		try {
			direccionDondeApunta = direcciones.anyOne()
		}
		catch e {
			direccionDondeApunta = direccionDondeApunta.opuesto()
		}
	}

	method puedeAvanzarHacia(unaDireccion) {
		const elementosEnDireccion = game.getObjectsIn(unaDireccion.siguiente(position))
		return elementosEnDireccion.isEmpty() or (elementosEnDireccion.size() == 1 and elementosEnDireccion.contains(jugador))
	}
	method pasarFrame() {
		frame = (frame + 1) % 4
	}
	method image() = "bman/bichito_" + direccionDondeApunta.toString() + frame.toString() + ".png"
}
// BLOQUES - BOMBA - FLAMA
class Elemento {
	const property position
	method dibujar() {
		game.addVisual(self)
	}
}

class ElementoDinamico inherits Elemento {
	override method dibujar() {
		super()
 		jugador.refrescarFrame()
	}
	method remover() {
		game.removeVisual(self)
		game.removeTickEvent(position.toString())
	}
}


class Bloque inherits Elemento {
	method image() = "bman/solidBlock.png"
	method explotar() {game.uniqueCollider(self).remover()}
	method chocarJugador() {jugador.retroceder()}
}

class BloqueVulnerable inherits Bloque {
	override method image() = "bman/explodableBlock.png"
	override method explotar() {game.removeVisual(self)}
}

class Bomba inherits ElementoDinamico {
	var frame = 0
	var acabaDeSerPlantada = true
	var alcance = 1
	
	override method dibujar() {
			super()
			game.onTick(800,position.toString(),{self.animar()})
 			game.schedule(3000,{self.explotar()})
	}
 	method explotar() {
 		if(game.hasVisual(self)) {
 			self.remover()
 			jugador.agregarBombaDisponible()
			self.expandirExplosion()
 		}
 	}
 	
 	method expandirExplosion() { //que se acorte al colisionar con bloques o bombas
 		new Flama(position=position).dibujar()
 		(1..alcance).forEach {n => new Flama(position=position.up(n)).dibujar()}
 		(1..alcance).forEach {n => new Flama(position=position.right(n)).dibujar()}
 		(1..alcance).forEach {n => new Flama(position=position.down(n)).dibujar()}
 		(1..alcance).forEach {n => new Flama(position=position.left(n)).dibujar()}
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
 
 class Flama inherits ElementoDinamico {
 	var frame = 0
 	override method dibujar() {
 		super()
 		game.onTick(100,position.toString(),{self.animar()})
 		game.onCollideDo(self,{elemento => elemento.explotar()})
 		game.schedule(2000,{self.remover()})
 	}
 	
 	method explotar() {}
 	
 	override method remover() {
 		if(game.hasVisual(self)) {
 			super()
 			jugador.agregarBombaDisponible()
 		}
 	}
 
 	method chocarJugador() {}

 	method image() = "bman/flama" + frame.toString() + ".png"
 	method animar() {
 		frame = (frame + 1) % 5
 	}
 }