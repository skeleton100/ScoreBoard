enum Uma{
  uma5_10('5-10', 5, 10),
  uma10_20('10-20', 10, 20),
  uma10_30('10-30', 10, 30),
  uma20_30('20-30', 20, 30);

  const Uma(
    this.displayText,
    this.uma1,
    this.uma2,
  );

  final String displayText;
  final int uma1;
  final int uma2;
}

enum Oka{
  oka25('25000点持ち30000点返し', 20),
  oka26('26000点持ち30000点返し', 16),
  oka27('27000点持ち30000点返し', 12),
  oka30('30000点持ち30000点返し', 0);

  const Oka(
    this.displayText,
    this.oka,
  );

  final String displayText;
  final int oka;
}