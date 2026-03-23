import { defineConfig } from 'astro/config'
import starlight from '@astrojs/starlight'
import sitemap from '@astrojs/sitemap'

export default defineConfig({
  site: 'https://y0mcp.dev',
  integrations: [
    sitemap(),
    starlight({
      title: 'y0mcp',
      description: 'Control your dev projects from Slack using your claude.ai subscription.',
      logo: { src: './src/assets/favicon.png', alt: 'y0mcp' },
      head: [
        { tag: 'meta', attrs: { property: 'og:image', content: 'https://y0mcp.dev/og-image.png' } },
        { tag: 'meta', attrs: { property: 'og:type', content: 'website' } },
        { tag: 'meta', attrs: { name: 'twitter:card', content: 'summary_large_image' } },
        { tag: 'meta', attrs: { name: 'twitter:image', content: 'https://y0mcp.dev/og-image.png' } },
      ],
      defaultLocale: 'en',
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/es-ua/y0mcp' },
      ],
      sidebar: [
        {
          label: 'Getting Started',
          items: [
            { label: 'Quick Start', slug: 'guides/quickstart' },
            { label: 'Setup Slack App', slug: 'guides/slack-app' },
            { label: 'Always-on Setup', slug: 'guides/always-on' },
          ]
        },
        {
          label: 'Guides',
          items: [
            { label: 'Multiple Projects', slug: 'guides/multi-project' },
            { label: 'Permission Relay', slug: 'guides/permissions' },
            { label: 'Dozzle Logs', slug: 'guides/dozzle' },
            { label: 'Token Refresh', slug: 'guides/token-refresh' },
          ]
        },
        {
          label: 'Reference',
          items: [
            { label: 'Configuration', slug: 'reference/config' },
            { label: 'Roadmap', slug: 'reference/roadmap' },
          ]
        }
      ],
      customCss: ['./src/styles/custom.css'],
    }),
  ],
})
