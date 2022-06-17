import wollok.game.*

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
		
		posiciones.forEach { pos => new Bloque(position = pos)}
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
		listaFilas.forEach{nroFila => new Bloque(position = game.at(nroColumna,nroFila))}
	}
	// El siguiente método todavía no se usa pero puede llegar a servir más adelante
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
		new Enemigo(id=1,position=game.at(5,5),direccion=oeste).dibujar()
		new Enemigo(id=2,position=game.at(1,7),direccion=oeste).dibujar()
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
		listaPosColumnas.forEach{posColumna => new BloqueVulnerable(position = game.at(posColumna,posFila))}
	}
}

class Personaje {
	var position
	var direccion
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

object jugador inherits Personaje(position=game.at(1,1),direccion=sur) {
	var bombasDisponibles = 1
	
	method iniciar() {
		game.addVisual(self)

		keyboard.up().onPressDo({self.mover(norte)})
		keyboard.right().onPressDo({self.mover(este)})
		keyboard.left().onPressDo({self.mover(oeste)})
		keyboard.down().onPressDo({self.mover(sur)})
		keyboard.d().onPressDo({self.plantarBomba()})

		game.onCollideDo(self,{elemento => elemento.chocarJugador()})
	}

	method retroceder() { 
		position = direccion.opuesto().siguiente(position)
	}
	
	method plantarBomba() {
		if (self.puedePlantarBomba())
			new Bomba(position = position)
			bombasDisponibles -= 1
	}
	
	method explotar() {
		self.morir()
	}
	
	method morir() {
		game.removeVisual(self)
	}

	method puedePlantarBomba() = game.getObjectsIn(position).size() == 1 and bombasDisponibles > 0
	method agregarBombaDisponible() {bombasDisponibles += 1}
	
	method refrescarFrame() {
		game.removeVisual(self)
		game.addVisual(self)
	}
	override method image() = "bman/bman_" + super()
}

class Enemigo inherits Personaje {
	const id
	
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

class Bloque {
	const property position
	method initialize() {
		game.addVisual(self)
	}
	method image() = "bman/solidBlock.png"
	method explotar() {game.uniqueCollider(self).remover()}
	method chocarJugador() {jugador.retroceder()}
}

class BloqueVulnerable inherits Bloque {
	method initialize() {
		game.addVisual(self)
	}
	override method image() = "bman/explodableBlock.png"
	override method explotar() {game.removeVisual(self)}
}

class Bomba {
	const property position
	var frame = 0
	var acabaDeSerPlantada = true
	var alcance = 1
	
	method initialize() {
			game.addVisual(self)
			jugador.refrescarFrame()
			game.onTick(800,position.toString(),{self.animar()})
 			game.schedule(3000,{self.explotar()})
	}
 	method explotar() {
 		if(game.hasVisual(self)) {
			game.removeVisual(self)
			game.removeTickEvent(position.toString())
 			jugador.agregarBombaDisponible()
			self.expandirExplosion()
 		}
 	}
 	
 	method expandirExplosion() {
 		new Flama(position=position)
 		(1..alcance).forEach {n => new Flama(position=position.up(n))}
 		(1..alcance).forEach {n => new Flama(position=position.right(n))}
 		(1..alcance).forEach {n => new Flama(position=position.down(n))}
 		(1..alcance).forEach {n => new Flama(position=position.left(n))}
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
 
 class Flama {
 	const property position
 	var frame = 0
 	method initialize() {
 		game.addVisual(self)
		jugador.refrescarFrame()
 		game.onTick(100,position.toString(),{self.animar()})
 		game.onCollideDo(self,{elemento => elemento.explotar()})
 		game.schedule(2000,{self.remover()})
 	}
 	
 	method remover() {
 		if(game.hasVisual(self)) {
 			game.removeVisual(self)
			game.removeTickEvent(position.toString())
 			jugador.agregarBombaDisponible()
 		}
 	}
 	
 	method explotar() {}
 	method chocarJugador() {}

	method animar() { frame = (frame + 1) % 5 }
 	method image() = "bman/flama" + frame.toString() + ".png"

 }