package Lodestone.network

public enum NetworkSide {
    SERVERBOUND | CLIENTBOUND

    public func getOpposite() {
        match (this) {
            case SERVERBOUND => CLIENTBOUND
            case CLIENTBOUND => SERVERBOUND
        }
    }
}

public enum NetworkPhase {
    HANDSHAKING | PLAY | STATUS | LOGIN | CONFIGURATION
}

public interface PacketListener {

}