import wollok.game.*
import direcciones.*
import elementosDeEntorno.*

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
	method image() = "assets/bman/bman_" + direccion.toString() + frame.toString() + estaVivo.toString() + ".png"
}