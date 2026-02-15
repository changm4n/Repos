open class Builder<DependencyType> {
  public let dependency: DependencyType
  public init(dependency: DependencyType) {
    self.dependency = dependency
  }
}
