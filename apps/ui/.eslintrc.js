module.exports = {
    root: true,
    env: {
      node: true,
      browser: true
    },
    parser: 'vue-eslint-parser',
    parserOptions: {
      sourceType: 'module',
    },
    extends: [
      'eslint:recommended',
      'plugin:vue/vue3-recommended',
    ],
    rules: {
      // override/add rules settings here, such as:
      // 'vue/no-unused-vars': 'error'
    },
    globals: {
      config: "readable",
      Vue: true
    }
}