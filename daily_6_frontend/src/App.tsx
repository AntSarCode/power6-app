import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import AppLayout from './components/AppLayout';
import Home from './pages/Home';
import TaskInput from './pages/TaskInput';
import TaskReview from './pages/TaskReview';
import NotFound from './pages/NotFound';
import StreakTracker from './pages/StreakTracker';
import SubscriptionScreen from './pages/SubscriptionScreen';
import Dashboard from './pages/Dashboard';
import StatsDashboard from './pages/StatsDashboard';
import Button from './components/ui/Button';
import Card from './components/ui/Card';
import Input from './components/ui/Input';

export default function App() {
    return (
        <BrowserRouter>
            <AppLayout>
                <Navbar />
                <Routes>
                    <Route path="/" element={<Home />} />
                    <Route path="/input" element={<TaskInput />} />
                    <Route path="/review" element={<TaskReview />} />
                    <Route path="/streak" element={<StreakTracker />} />
                    <Route path="/subscribe" element={<SubscriptionScreen />} />
                    <Route path="/dashboard" element={<Dashboard />} />
                    <Route path="/stats" element={<StatsDashboard />} />
                    <Route path="/ui/button" element={
                        <Button variant="primary" onClick={() => alert("Clicked!")}>
                            Click Me
                        </Button>
                    } />
                    <Route path="/ui/card" element={
                        <Card title="Sample Card" description="This is a test card.">
                            <button className="mt-2 bg-blue-500 text-white px-3 py-1 rounded">Action</button>
                        </Card>
                    } />
                    <Route path="/ui/input" element={
                        <Input
                            value="Hello"
                            onChange={(e) => console.log(e.target.value)}
                            placeholder="Type something..."
                        />
                    } />
                    <Route path="*" element={<NotFound />} />
                </Routes>
            </AppLayout>
        </BrowserRouter>
    );
}
