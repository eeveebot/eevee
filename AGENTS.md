# Development Guide for Agentic Coding Agents

This guide provides essential information for agentic coding agents working with the eevee.bot codebase, which is a Hugo-based documentation site.

## Project Overview

This repository contains the documentation site for eevee.bot, a chatbot framework built with a microservices architecture. The site is built using Hugo and deployed to GitHub Pages.

## Build Commands

### Local Development

```bash
# Serve the site locally with live reload
hugo server --source ./hugo

# Serve with draft posts visible
hugo server --source ./hugo --buildDrafts --buildFuture

# Build the site for production
hugo --source ./hugo --gc --minify
```

### Production Build

The production build is automated through GitHub Actions. See `.github/workflows/hugo.yaml` for the exact build process.

## Linting and Testing

### Markdown Linting

```bash
# Check for basiclint (install if needed)
markdownlint --version || npm install -g markdownlint-cli

# Lint all markdown files
markdownlint '**/*.md' --ignore node_modules
```

### Link Checking

```bash
# Check for broken links (install if needed)
htmltest --version || go install github.com/wjdp/htmltest@latest

# Test links in built site
htmltest
```

### Running Single Tests

Since this is a documentation site, testing primarily involves:

1. Validating markdown syntax:
```bash
markdownlint hugo/content/docs/specific-section/file.md
```

2. Checking internal links in a specific file:
```bash
# After building site
htmltest -c .htmltest.yml path/to/page.html
```

3. Previewing changes:
```bash
hugo server --source ./hugo
```

## Code Style Guidelines

### File Organization

- Content files: `hugo/content/docs/`
- Static assets: `hugo/static/`
- Layout templates: `hugo/layouts/`
- Configuration: `hugo/hugo.toml`

### Markdown Formatting

- Use ATX-style headers (`## Header` not `Header\n======`)
- Wrap lines at 80 characters when possible
- Use proper indentation for code blocks (4 spaces)
- Use proper alt text for images
- Use relative links for internal documentation references

### Content Structure

- Documentation files should begin with a top-level header (#)
- Use proper hierarchy for section headers (##, ###, ####)
- Include a brief introduction at the beginning of each document
- Use code blocks with language identifiers for code examples
- Use tables for structured data when appropriate

### Naming Conventions

- Use lowercase filenames with hyphens as separators
- Use descriptive names that match the document title
- Place related documents in appropriately named subdirectories

### Front Matter

When creating new content files, include appropriate front matter:

```toml
+++
title = "Page Title"
description = "Brief description of the page content"
weight = 10
+++
```

### Code Examples

- Use fenced code blocks with language identifiers
- Ensure code examples are functional and accurate
- Include comments for complex code examples
- Use meaningful variable names in examples

### Images

- Place images in `hugo/static/images/` or appropriate subdirectories
- Use descriptive filenames
- Include alt text for accessibility
- Optimize images for web use

### Internal Links

- Use relative links for internal documentation: `[link text](../section/page/)`
- Use absolute URLs for external links: `[link text](https://example.com/)`
- Verify that all links work correctly before committing

### Error Handling

- Report broken links as issues
- Validate all code examples before adding them
- Ensure all images are properly referenced
- Check that table of contents is correctly generated

### Additional Guidelines

- Keep documentation concise and focused
- Use active voice rather than passive voice
- Define technical terms when first introduced
- Provide examples for complex concepts
- Update documentation when features change
- Review documentation for accuracy regularly
