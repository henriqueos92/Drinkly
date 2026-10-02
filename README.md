# Drinkly 💧 — hidratação no Apple Watch

App nativo para Apple Watch (Swift + SwiftUI) para acompanhar a ingestão de líquidos.
A ação principal, registrar água, leva **um toque**, seja na tela inicial, na complicação ou pela Siri.

- Meta diária calculada a partir do perfil (sexo, altura, peso e idade), com ajuste manual.
- Botões rápidos (+200, +300, +500, +750 ml… configuráveis) e volumes personalizados pela Digital Crown.
- Bebidas pré-configuradas: água, água de coco, suco, café, chá, refrigerante e outra.
- Avatar masculino/feminino que enche de água conforme o progresso, com animação de ~0,5 s.
- Histórico de hoje, ontem, últimos 7 dias, semana (seg–dom) e mês, com estatísticas.
- Lembretes inteligentes: começam só depois da primeira bebida do dia, respeitam o intervalo e a janela de horário.
- Complicações para o mostrador (WidgetKit no watchOS 9+, ClockKit no watchOS 8) e Smart Stack (watchOS 10+).
- Siri e Atalhos: "Adicionar 500 ml no Drinkly".
- Integração opcional com o Apple Health.
- Tudo fica no relógio, funciona offline e não pede login nem servidor.

> As metas são estimativas para bem-estar e **não constituem recomendação médica**.

---

## 1. Análise de compatibilidade (feita antes da implementação)

### 1.1 Versões de watchOS por modelo

| Modelo | Caixas | watchOS de fábrica | watchOS máximo |
|---|---|---|---|
| Apple Watch Series 3 | 38 mm / 42 mm | 4 | **8.8.1** (não recebe watchOS 9+) |
| Series 7 / 8 / 9 | **41 mm / 45 mm** | 8 / 9 / 10 | atual |
| Series 10 / 11 | 42 mm / 46 mm | 11 / 26 | atual |
| Ultra | 49 mm | 9 | atual |

O Series 3 não passa do watchOS 8, e os modelos de 41/45 mm (Series 7) saíram de fábrica com o watchOS 8.
Para atender aos três, a versão mínima tem que ser o **watchOS 8.0**. É o *deployment target* do app.

### 1.2 Telas

| Caixa | Pontos (largura × altura) | Pixels |
|---|---|---|
| 38 mm (S3) | 136 × 170 | 272 × 340 |
| 42 mm (S3) | 156 × 195 | 312 × 390 |
| 41 mm (S7–S9) | 176 × 215 | 352 × 430 |
| 45 mm (S7–S9) | 198 × 242 | 396 × 484 |

Os 41/45 mm têm tela maior, cantos mais arredondados e ~20–25% mais área útil que os 38/42 mm.
O layout não usa posições fixas. A tela inicial mede a largura com `GeometryReader`:

- **≥ 160 pt** (40/41/44/45/46/49 mm): avatar à esquerda e números à direita.
- **< 160 pt** (38/42 mm do Series 3) ou Dynamic Type de acessibilidade: avatar acima e números abaixo.

Fontes semânticas (`.title`, `.headline`…) acompanham o Dynamic Type. Textos longos usam `minimumScaleFactor`.
O avatar e a gota são vetores (`Shape`), então escalam sem perda.

### 1.3 APIs por versão e alternativas adotadas

| Recurso | Disponível em | No watchOS 8 (Series 3) |
|---|---|---|
| App SwiftUI (`@main App`), `TabView` paginado, `NavigationView`, `List`, `sheet`, `confirmationDialog`, `alert`, Dynamic Type | watchOS 7–8 | ✅ usado em todas as versões |
| `NavigationStack` | watchOS 9 | ➜ `NavigationView` |
| Swift Charts | watchOS 9 | ➜ barras próprias em SwiftUI (`ProgressBar`, `DayBarRow`) |
| SwiftData | watchOS 10 | ➜ arquivos JSON (`FileHydrationStore`) atrás do protocolo `HydrationStore` |
| `@Observable` | watchOS 10 | ➜ `ObservableObject` / `@Published` |
| `DatePicker` | watchOS 10 | ➜ `Picker` em roda com horários de 30 em 30 min |
| `.contentTransition(.numericText())` | watchOS 10 | ➜ `AnimatedNumberText` (`Animatable`), que conta 1.000 → 1.500 |
| Complicações **WidgetKit** | watchOS 9 | ➜ **ClockKit** (`ComplicationController`), com os mesmos dados |
| Smart Stack | watchOS 10 | ➜ não existe no watchOS 8 (o widget retangular aparece no Smart Stack a partir do 10) |
| `containerBackground(for: .widget)` | watchOS 10 (obrigatório lá) | usado com `if #available` |
| App Intents (Siri, Atalhos, App Shortcuts) | watchOS 9 | ➜ indisponível; no watchOS 8 a complicação ClockKit abre o app já com os botões rápidos |
| HealthKit (`dietaryWater`), UserNotifications, Digital Crown, hápticos | watchOS 2–6 | ✅ |

**Funcionalidades que não existem em todas as versões:**

1. **Siri, Atalhos e App Shortcuts** só a partir do watchOS 9. No Series 3, o caminho mais curto é a complicação, que abre o app com os botões rápidos.
2. **Smart Stack** só a partir do watchOS 10.
3. **Tocar na complicação e cair direto no "Registro rápido"**: no watchOS 9+ o widget usa `widgetURL(drinkly://quick-add)` e abre a tela `QuickAddView` (+200/+300/+500). No watchOS 8 (ClockKit), tocar abre o app na tela inicial, que já tem os mesmos botões. Ou seja, também 1 toque.
4. **Botões interativos dentro da própria complicação** (registrar sem abrir o app) não foram usados. Esse recurso só existe em versões recentes do watchOS e não funcionaria no Series 3. A complicação abre o registro rápido, o que custa um toque a mais.
5. **Simulador do Series 3**: as versões recentes do Xcode podem não oferecer o runtime de simulador do watchOS 8. Nesse caso, o teste no Series 3 precisa de um relógio físico (veja a seção 5).

### 1.4 Arquitetura de compatibilidade

```
                 ┌──────────────────────── DrinklyCore (Swift Package, só Foundation) ───────────────────────┐
                 │ Models · HydrationGoalCalculator · HydrationProgress · ReminderPlanner · HistoryCalculator │
                 │ HydrationService (fachada) · HydrationStore (protocolo) · FileHydrationStore (JSON)        │
                 └──────────────▲───────────────────────────────▲───────────────────────────────▲─────────────┘
                                │                               │                               │
     App watchOS 8+ (DrinklyWatch)                Shared/HydrationSnapshot          Extensão WidgetKit (watchOS 9+)
     SwiftUI · ViewModels · Notification/        (leitura do App Group)            DrinklyWidgets: circular, canto,
     HealthKit/Complication services ·                  ▲          ▲               retangular (Smart Stack), inline
     ClockKit ComplicationController (watchOS 8) ───────┘          └─────────────────────────────┘
     App Intents (watchOS 9+, `@available`)
```

- A regra de negócio existe **uma vez só**, no pacote `DrinklyCore`. Ele não importa SwiftUI/WatchKit e compila até no Linux.
- WidgetKit e ClockKit leem o mesmo `HydrationSnapshot`, então nenhuma lógica é duplicada.
- No watchOS 9+, o `ComplicationController` não oferece descritores, o que evita complicações duplicadas no editor de mostradores.
- WidgetKit e AppIntents são *weak-linked* (`-weak_framework`), para que o app abra no watchOS 8.

---

## 2. Estrutura do projeto

```
Drinkly/
├── project.yml                     # Definição do projeto (XcodeGen)
├── Drinkly.xcodeproj               # Projeto Xcode gerado a partir do project.yml
├── Packages/DrinklyCore/           # Regras de negócio + persistência (Swift Package)
│   ├── Sources/DrinklyCore/
│   │   ├── Models/                 # UserProfile, DrinkRecord, BeverageType, Gender, DayKey,
│   │   │                           # ReminderSettings, GoalHistory, DailySummary
│   │   ├── BusinessRules/          # HydrationGoalCalculator, HydrationProgress, ReminderPlanner,
│   │   │                           # ReminderMessageComposer, HistoryCalculator
│   │   ├── Persistence/            # HydrationStore (protocolo), FileHydrationStore, InMemoryHydrationStore
│   │   ├── Services/               # HydrationService (fachada + observadores)
│   │   ├── Formatting/             # VolumeFormatter ("1.250 / 2.500 ml")
│   │   └── Navigation/             # DeepLink (drinkly://quick-add)
│   └── Tests/DrinklyCoreTests/     # 60 testes unitários
├── DrinklyWatch/                   # App do relógio (watchOS 8+)
│   ├── App/                        # DrinklyApp, AppEnvironment (composição), RootView
│   ├── Views/
│   │   ├── Dashboard/              # Tela inicial + resumo de progresso
│   │   ├── Avatar/                 # Silhuetas vetoriais e nível de água animado
│   │   ├── AddDrink/               # Adicionar bebida, volume personalizado, registro rápido
│   │   ├── Today/                  # Registros do dia, edição e exclusão
│   │   ├── History/                # Histórico: dia, últimos 7 dias, semana, mês
│   │   ├── Settings/               # Perfil, meta, bebidas rápidas, notificações, Health, dados
│   │   ├── Onboarding/             # Configuração inicial em 5 etapas
│   │   └── Components/             # Botões, barras, pickers, tema, texto animado
│   ├── ViewModels/                 # HydrationViewModel, HistoryViewModel, OnboardingViewModel
│   ├── Services/                   # NotificationService, HealthKitService, ComplicationService
│   ├── Complications/              # ComplicationController (ClockKit, watchOS 8)
│   ├── Intents/                    # App Intents + App Shortcuts (watchOS 9+)
│   └── Resources/                  # Assets (ícone, cor), Info.plist, entitlements
├── DrinklyWidgets/                 # Extensão WidgetKit (complicações watchOS 9+, Smart Stack)
├── Shared/                         # Código comum app/widget: AppGroup, HydrationSnapshot, DropShape
├── DrinklyWatchTests/              # Testes unitários do app (ViewModels)
├── DrinklyWatchUITests/            # Testes de UI
└── .github/workflows/ci.yml        # CI: swift test (Linux) + xcodebuild (macOS)
```

### Camadas

| Camada | Onde | Responsabilidade |
|---|---|---|
| Models | `DrinklyCore/Models` | Dados puros e `Codable` |
| Business Rules | `DrinklyCore/BusinessRules` | Meta, percentual, restante, lembretes, estatísticas. Tudo puro e testado |
| Persistence | `DrinklyCore/Persistence` | `HydrationStore` (protocolo) e implementação em arquivos |
| Services | `DrinklyCore/Services` + `DrinklyWatch/Services` | `HydrationService` orquestra; serviços de sistema reagem a mudanças |
| Notification | `NotificationService` + `ReminderPlanner` | Agendamento no sistema, sem timers |
| Health | `HealthKitService` | Opcional e desligável |
| Widget/Complications | `DrinklyWidgets`, `ComplicationController`, `ComplicationService` | Mostrador e Smart Stack |
| ViewModels | `DrinklyWatch/ViewModels` | Estado para as telas |
| UI | `DrinklyWatch/Views` | SwiftUI |

**Efeitos colaterais desacoplados.** Toda alteração feita pelo `HydrationService` (adicionar, editar, excluir, mudar o perfil) é entregue a observadores:

```
model.add(500)  →  HydrationService.addDrink  →  grava no disco (só o arquivo do mês)
                                              ├→ HydrationViewModel   (UI: contador, %, avatar)
                                              ├→ NotificationService  (recalcula o próximo lembrete)
                                              ├→ ComplicationService  (recarrega a complicação)
                                              └→ HealthKitService     (grava no Apple Health, se ativo)
```

### Regras de negócio importantes

- **Meta**: `HydrationGoalCalculator` aplica `meta = peso × fator_ml_por_kg` (35 ml/kg por padrão), arredondada a 50 ml e limitada a 1.000–6.000 ml. Para mudar a regra, edite `HydrationGoalCalculator.default` ou crie outra `HydrationGoalFormula`. As telas não mudam. Exemplo: 120 kg × 35 = **4.200 ml**.
- **Percentual**: não é limitado a 100% (3.000 / 2.500 = **120%**). Antes de atingir a meta, nunca mostra "100%" (2.490 / 2.500 = 99%).
- **Reset diário sem processo à meia-noite**: o "hoje" é derivado da data local do dispositivo, e o progresso é a soma dos registros desse dia. O histórico nunca é apagado.
- **Meta histórica**: `GoalHistory` guarda a meta vigente em cada dia. Mudar a meta hoje não altera o percentual de dias passados.
- **Persistência**: só registros individuais são gravados. Totais diários, semanais e mensais são sempre calculados, sem risco de inconsistência. Há um arquivo JSON por mês (`records/2026-10.json`), então cada gravação reescreve só um mês, o que suporta vários anos de histórico.

### Lembretes

```
08:30 primeira bebida → 10:00 → 11:30 → 13:00 → 14:30 …  (intervalo de 90 min)
```

- Antes da primeira bebida do dia, não há lembrete.
- Cada bebida recalcula a sequência a partir dela, então nunca chega um lembrete logo depois de beber.
- Nada é enviado fora da janela configurada (ex.: 08:00–22:00) e nada é agendado para o dia seguinte.
- Opcionalmente, os lembretes param quando a meta é atingida.
- As mensagens variam: "Que tal mais um copo de água?", "Você já bebeu 1.500 ml hoje.", "Faltam 700 ml para sua meta.", "Você está quase chegando à sua meta!", "Já faz 3 h desde sua última bebida."
- A notificação tem ações rápidas ("+200 ml de água").
- Não há timers nem processos contínuos: os lembretes são agendados no `UNUserNotificationCenter` (no máximo 48, abaixo do limite de 64 do sistema).

### Apple Health

É desligado por padrão e pode ser ativado em **Ajustes › Apple Health**. Cada registro vira uma amostra de **Água** (`dietaryWater`) com `HKMetadataKeySyncIdentifier` igual ao id do registro:

- editar substitui a amostra (`HKMetadataKeySyncVersion`), sem duplicar;
- excluir remove a amostra;
- o Drinkly **não importa** água de outros apps, então não há contagem dupla no próprio histórico.

---

## 3. Executar no Xcode

### Requisitos

- Mac com **Xcode 15 ou mais recente**. O CI usa o Xcode padrão do `macos-15`.
- Uma conta Apple (gratuita para simulador; paga para instalar em relógio e publicar).

### Passos

1. Abra `Drinkly.xcodeproj`.
2. Em **Build Settings** do projeto (ou no `project.yml`), ajuste:
   - `BUNDLE_ID_PREFIX`: seu prefixo, ex.: `com.seunome`;
   - `DEVELOPMENT_TEAM`: seu Team ID. Também dá para escolher o time em *Signing & Capabilities* de cada target.

   Os bundle IDs passam a ser `…hydration.watchkitapp` (app) e `…hydration.watchkitapp.widgets` (extensão). O App Group passa a ser `group.<prefixo>.hydration`.
3. Em *Signing & Capabilities* dos targets **DrinklyWatch** e **DrinklyWidgets**, confirme o **App Group** (o mesmo nos dois) e, no app, o **HealthKit**.
4. Selecione o esquema **Drinkly** e um simulador de Apple Watch, então ⌘R.

> O projeto foi gerado com o [XcodeGen](https://github.com/yonaskolb/XcodeGen). Para alterar targets e configurações, edite o `project.yml` e rode `xcodegen generate`. Não edite o `.pbxproj` à mão.

### Testes

| O quê | Como |
|---|---|
| Regras de negócio (60 testes) | `cd Packages/DrinklyCore && swift test` (macOS ou Linux) ou ⌘U no esquema **Drinkly** |
| ViewModels | ⌘U no esquema **Drinkly** (target `DrinklyWatchTests`) |
| UI | ⌘U no esquema **Drinkly** (target `DrinklyWatchUITests`) |

Cobertura dos testes de regra: cálculo da meta, percentual, quantidade restante, meta atingida/excedida, virada de dia (inclusive meia-noite exata), histórico, meta histórica, edição (inclusive mudando o dia), exclusão, ativação dos lembretes após a primeira bebida, cálculo do próximo lembrete, janela de horário, intervalos configuráveis, volumes personalizados, persistência entre instâncias (app/widget) e vários anos de histórico.

Os testes de UI iniciam o app com `-ui-testing`. Nesse modo os dados ficam em memória e notificações, Health e complicações ficam desligados. Eles cobrem onboarding, estado vazio, adição rápida com um toque, meta atingida/ultrapassada e bebida com volume escolhido.

---

## 4. Testar no simulador

1. **Tamanhos de tela**: em *Window › Devices and Simulators › Simulators*, crie simuladores de 41 mm e 45 mm (Series 7/8/9) e, se o seu Xcode oferecer, 38/42 mm. Rode o app e os testes de UI em cada um.
2. **Dynamic Type**: no simulador, *Settings › Display & Brightness › Text Size*. Ou use o *Accessibility Inspector* do Xcode. Em tamanhos de acessibilidade, o avatar fica acima dos números.
3. **VoiceOver**: *Settings › Accessibility › VoiceOver*. O botão "+500 ml" é lido como "Adicionar 500 mililitros de água".
4. **Complicação**:
   - watchOS 9+: no simulador, segure o mostrador, toque em *Editar* e adicione a complicação **Drinkly**. Para depurar só o widget, rode o esquema **DrinklyWidgets**.
   - watchOS 8: a complicação vem do ClockKit, e o mostrador precisa ser um que aceite a família.
5. **Registro rápido pela complicação**: toque na complicação. Abre a tela com +200/+300/+500. Para simular sem mostrador, rode `xcrun simctl openurl booted drinkly://quick-add`.
6. **Virada de dia**: com o app aberto, mude a hora do Mac para 23:59 e espere a meia-noite (ou mude a data). O progresso volta a zero e o dia anterior aparece em *Histórico › Ontem*.
7. **Notificações**: registre uma bebida e, em *Ajustes › Notificações*, use o intervalo "Personalizado" com 15 min para ver o lembrete chegar. Feche o app para recebê-lo como notificação.
8. **Light/Dark**: o watchOS só tem aparência escura, e as cores foram escolhidas para alto contraste sobre o preto. Nas complicações, o modo *tinted* do mostrador é atendido com `widgetAccentable()`.
9. **Orientação**: o relógio é sempre retrato. O app aceita "pulso esquerdo/direito" (retrato invertido), que o sistema gerencia.

---

## 5. Instalar em um Apple Watch físico

1. O relógio precisa estar pareado com um iPhone conectado ao Mac por cabo ou na mesma rede. O app é **watch-only**, não há app de iPhone.
2. No Xcode, configure o time de assinatura nos dois targets (veja a seção 3).
3. **watchOS 9 ou mais recente**: ative o *Modo de Desenvolvedor* no relógio (*Ajustes › Privacidade e Segurança › Modo de Desenvolvedor*) e reinicie. No iPhone, ative também o Modo de Desenvolvedor, se for pedido.
4. Em *Window › Devices and Simulators*, espere o relógio aparecer e terminar a preparação ("Preparing…" pode levar alguns minutos).
5. Selecione o relógio como destino no esquema **Drinkly** e pressione ⌘R.
6. Primeira execução: aceite as notificações no fim do onboarding. Adicione a complicação pelo app Watch do iPhone ou segurando o mostrador.

**Apple Watch Series 3 (watchOS 8.8.1).** Funciona com o mesmo projeto. Observações:

- Muitos Series 3 têm apenas 8 GB, e a instalação pode exigir espaço livre.
- A instalação por cabo/rede pode ser lenta.
- Siri/Atalhos e Smart Stack não existem nesse modelo (veja a seção 1.3).

**Distribuição (App Store / TestFlight).** Use *Product › Archive* com o esquema **Drinkly** e envie pelo Organizer. Antes, confirme:

- os identificadores e o App Group no portal da Apple;
- a capacidade HealthKit;
- os textos de privacidade (`NSHealthUpdateUsageDescription`).

A Apple exige periodicamente um SDK mínimo para envio (por exemplo, Xcode 16 / watchOS 11 SDK desde abril de 2025). Confira o requisito vigente em developer.apple.com. Se uma versão futura do Xcode deixar de aceitar o watchOS 8 como versão mínima, o suporte ao Series 3 terá que ser encerrado. Nesse caso, eleve o *deployment target* para 9.0 e remova o `ComplicationController`. O restante do código não muda.

---

## 6. Limitações conhecidas e próximos passos

- **Compilação**: as regras de negócio foram compiladas e testadas (`swift test`, 60/60). O código SwiftUI/watchOS foi escrito contra as APIs de cada versão, mas o ambiente em que foi produzido não tinha Xcode. A validação de build e dos testes no simulador fica com o workflow de CI incluído (`.github/workflows/ci.yml`, job *watchOS app*) ou com a primeira compilação local.
- **Exportação de dados**: o item aparece em Ajustes como "em breve". Os dados já estão em JSON legível, então exportar é simples.
- **Sincronização futura (Watch → iPhone → iCloud)**: o ponto de extensão é o protocolo `HydrationStore`, mais o campo `revision` de cada registro. Uma implementação com WatchConnectivity/CloudKit pode substituir ou envolver o `FileHydrationStore` sem mudar regras de negócio ou telas.
- **Leitura do Apple Health**: hoje o app só escreve. Ler (por exemplo, para mostrar água registrada por outros apps) exigiria permissão de leitura adicional. O `HealthKitService` concentra esse ponto.
- **Coeficiente de hidratação por bebida** (ex.: café contando menos): não aplicado, porque o volume é registrado como ingerido. Isso pode ser adicionado no `DrinklyCore` sem tocar nas telas.

## Privacidade

Os dados ficam apenas no relógio, no contêiner do App Group, com criptografia de arquivo do sistema. Não há backend, login, analytics nem rede. O app funciona totalmente offline.
