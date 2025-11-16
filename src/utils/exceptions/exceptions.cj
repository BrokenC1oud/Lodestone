package Lodestone.utils.exceptions

public open class SingletonConflictionException <: Exception {
    public init() {
        super("Singleton Confliction")
    }

    public init(message: String) {
        super(message)
    }

    public open override func getClassName(): String {
        "SingletonConflictionException"
    }
}