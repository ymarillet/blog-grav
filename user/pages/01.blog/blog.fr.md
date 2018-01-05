---
title: Accueil
blog_url: blog
body_classes: header-image fullwidth

sitemap:
    changefreq: monthly
    priority: 1.03

content:
    items: @self.children
    order:
        by: date
        dir: desc
    limit: 5
    pagination: true

feed:
    description: Bienvenue sur mon blog tech & lifestyle, partage de connaissances
    limit: 10

pagination: true
---
