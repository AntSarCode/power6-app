import React from 'react';

type InputProps = {
    value: string;
    onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
    placeholder?: string;
    className?: string;
};

const Input = ({ value, onChange, placeholder, className = '' }: InputProps) => {
    return (
        <input
            value={value}
            onChange={onChange}
            placeholder={placeholder}
            className={`w-full p-3 rounded-xl bg-muted text-primary placeholder:text-gray-500 outline-none focus:ring-2 focus:ring-accent ${className}`}
        />
    );
};

export default Input;
