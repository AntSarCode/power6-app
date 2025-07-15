/** @type {import('tailwindcss').Config} */
module.exports = {
    content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
    safelist: [
        'bg-primary',
        'text-primary',
        'bg-accent',
        'text-white',
        'hover:bg-blue-900',
        'hover:bg-teal-700',
        'bg-transparent',
        'border',
        'border-primary',
        'hover:text-white',
    ],
    theme: {
        extend: {
            colors: {
                primary: '#001F3F',
                secondary: '#FFD700',
                accent: '#008080',
                muted: '#CBD5E1',
                surface: '#1E293B',
                error: '#EF4444',
                success: '#10B981',
            },
            fontFamily: {
                sans: ['Inter', 'sans-serif'],
            },
            borderRadius: {
                xl: '1rem',
                '2xl': '1.5rem',
            },
        },
    },
    plugins: [],
};
