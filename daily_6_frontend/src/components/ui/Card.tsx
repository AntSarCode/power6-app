type CardProps = {
    title: string;
    description: string;
    children?: React.ReactNode;
};

const Card = ({ title, description, children }: CardProps) => (
    <div className="p-4 border rounded-lg shadow-md bg-white text-black">
        <h2 className="text-xl font-bold mb-2">{title}</h2>
        <p className="text-sm mb-2">{description}</p>
        {children && <div className="mt-2">{children}</div>}
    </div>
);


export default Card;
