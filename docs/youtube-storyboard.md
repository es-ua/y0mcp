# y0mcp — Раскадровка YouTube ролика

**Формат:** 60–90 секунд, вертикаль (Shorts) или горизонталь
**Стиль:** screencast + motion graphics, тёмная тема, минималистично
**Музыка:** lo-fi / tech ambient, без вокала
**Голос:** AI voiceover (ElevenLabs / Play.ht) или текст на экране

---

## Сцена 1 — Проблема (0:00–0:08)

**Визуал:** Разработчик сидит за ноутбуком, переключается между окнами терминала. На экране 3 открытых терминала Claude Code — в каждом Permission request ждёт ответа. Разработчик не успевает.

**Текст на экране:**
> "3 projects. 3 terminals. Claude keeps asking for permission."
> "You can't leave your desk."

**Настроение:** Проблема, friction, неудобство.

---

## Сцена 2 — А что если через Slack? (0:08–0:12)

**Визуал:** Плавный переход — экран телефона, открыт Slack. Уведомление от бота y0mcp.

**Текст на экране:**
> "What if Claude worked through Slack?"

**Настроение:** Интрига, переход к решению.

---

## Сцена 3 — Демо: отправка команды (0:12–0:22)

**Визуал:** Экран Slack (десктоп или мобильный). Канал `#project-api`.

Пользователь пишет:
> "check why tests are failing on staging"

Бот ставит реакцию :thinking_face:

Через 3 секунды бот отвечает:
> "Found the issue. Test `auth.spec.ts` fails because the JWT secret changed in env. Fix: update `STAGING_JWT_SECRET` in `.env.staging`"

**Текст на экране:** (подпись снизу)
> "Send a message → Claude works in your repo"

---

## Сцена 4 — Демо: Permission relay (0:22–0:35)

**Визуал:** Тот же Slack канал. Бот пишет:

> 🔴 **Permission required**
>
> **Action:** `git push origin staging`
> **Reason:** Deploy fix to staging
>
> React ✅ to approve or ❌ to deny
> _Timeout: 5 minutes_

Пользователь ставит ✅.

Сообщение обновляется:
> ✅ **Approved** — `git push origin staging`

Бот пишет:
> "Pushed to staging. Tests passing now."

**Текст на экране:**
> "Approve risky actions with a reaction. From your phone."

---

## Сцена 5 — Multi-project (0:35–0:42)

**Визуал:** Slack sidebar — видно 3 канала с зелёными точками:
- `#project-api` — бот онлайн
- `#project-frontend` — бот онлайн
- `#project-infra` — бот онлайн

Быстрое переключение между каналами, в каждом своя переписка с ботом.

**Текст на экране:**
> "One channel per project. As many as you need."

---

## Сцена 6 — Always-on (0:42–0:48)

**Визуал:** Анимация — ноутбук закрывается. Рядом появляется иконка Mac Mini / сервера. Пульсирующая зелёная точка — "online".

Показать Slack уведомление:
> 🟢 **y0mcp agent started**
> Agent: `project-api` | Channel: #project-api
> Token valid for ~11h

**Текст на экране:**
> "Runs 24/7 as a system service. Auto-restarts. Auto token refresh."

---

## Сцена 7 — Установка (0:48–0:58)

**Визуал:** Терминал (тёмная тема). Быстрый набор команд с анимацией:

```
/plugin marketplace add es-ua/y0mcp
/plugin install slack@y0mcp
```

Затем:
```
bash scripts/new-agent.sh
```

Промпт: `Agent name:` → `my-project` ✓
Промпт: `Slack channel ID:` → `C07...` ✓

**Текст на экране:**
> "Setup in 2 minutes. No API key needed."

---

## Сцена 8 — Сравнение (0:58–1:06)

**Визуал:** Таблица сравнения (motion graphics), появляется построчно:

|  | OpenClaw | Channels | y0mcp |
|---|---|---|---|
| Slack | ✓ | ✗ | ✓ |
| Permission relay | ✗ | ✗ | ✓ |
| claude.ai subscription | ✗ | ✓ | ✓ |
| API key required | ✓ | ✗ | ✗ |
| Always-on | ✗ | ✗ | ✓ |

Колонка y0mcp подсвечивается.

**Текст на экране:**
> "Best of both worlds."

---

## Сцена 9 — CTA (1:06–1:15)

**Визуал:** Логотип y0mcp по центру, тёмный фон.

Под ним:
> **y0mcp.dev**
> github.com/es-ua/y0mcp

Кнопки: ⭐ Star on GitHub / Get Started

**Текст на экране / voiceover:**
> "y0mcp — control your dev projects from Slack."
> "Open source. Free. Works with your claude.ai subscription."

---

## Итого

| Сцена | Хрон | Суть |
|---|---|---|
| 1. Проблема | 0:00–0:08 | 3 терминала, не уйти от компьютера |
| 2. Переход | 0:08–0:12 | "А что если через Slack?" |
| 3. Команда | 0:12–0:22 | Отправил сообщение → получил ответ |
| 4. Permission | 0:22–0:35 | Approve/deny реакцией |
| 5. Multi-project | 0:35–0:42 | 3 канала, 3 проекта |
| 6. Always-on | 0:42–0:48 | Работает 24/7 как сервис |
| 7. Установка | 0:48–0:58 | 2 команды и готово |
| 8. Сравнение | 0:58–1:06 | Таблица vs конкуренты |
| 9. CTA | 1:06–1:15 | Ссылки, призыв к действию |

---

## Промпт для AI-генерации видео

Скопируй этот промпт в Sora / Runway / Kling / Vidu:

```
Create a 75-second tech product demo video for "y0mcp" — an open source
Slack plugin for Claude Code AI assistant.

Style: dark theme, minimal motion graphics, developer-focused.
Similar to: Vercel product videos, Linear changelogs, Raycast demos.

The video shows a developer controlling AI coding agents through Slack:
- Problem: developer stuck at terminal approving AI actions manually
- Solution: messages and permission approvals happen in Slack
- Demo: realistic Slack UI with bot messages, permission requests, emoji reactions
- Multi-project: multiple Slack channels, each connected to a different repo
- Always-on: runs as a system service, auto-restarts, token refresh
- Install: two commands in terminal
- Comparison table vs competitors
- CTA: y0mcp.dev, GitHub link

Color palette: dark background (#1a1a2e), purple accent (#7c3aed),
green for success (#22c55e), Slack brand purple (#4A154B).
Font: monospace for code, clean sans-serif for text.
Music: ambient lo-fi, calm tech vibe.
No face, no voice — text on screen only (or add AI voiceover separately).
```

---

## Альтернатива: собрать из скринкастов

Если AI видео не устраивает по качеству:

1. **Запиши скринкаст Slack** — создай тестовый канал, напиши сообщения от себя и от бота (или mock в Figma)
2. **Запиши терминал** — используй [asciinema](https://asciinema.org) или просто screen recording
3. **Склей в CapCut / DaVinci** — добавь текст, переходы, музыку
4. **Добавь voiceover** — ElevenLabs или Play.ht по тексту из сцен выше
