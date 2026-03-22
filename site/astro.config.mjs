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
      logo: { src: './src/assets/logo.svg' },
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
