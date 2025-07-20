import {useEffect, useState} from 'react';
import {getUserSession} from '../services/api';

const useAuth = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUser = async () => {
      try {
        const session = await getUserSession();
        setUser(session);
      } catch (e) {
        setUser(null);
      } finally {
        setLoading(false);
      }
    };

    fetchUser();
  }, []);

  return {user, loading};
};

export default useAuth;
