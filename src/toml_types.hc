// toml_types.hc — Core TOML types

pub type Toml {
  TStr(value: string),
  TInt(value: int),
  TFloat(value: float),
  TBool(value: bool),
  TDatetime(value: string),
  TArray(items: list<Toml>),
  TTable(entries: list<(string, Toml)>)
}
