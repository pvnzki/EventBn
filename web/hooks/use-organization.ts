import { useState, useEffect } from 'react';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

export interface Organization {
  organization_id: number;
  user_id: number;
  name: string;
  description?: string;
  logo_url?: string;
  contact_email?: string;
  contact_number?: string;
  website_url?: string;
  created_at: string;
  updated_at: string;
  user: {
    user_id: number;
    name: string;
    email: string;
  };
}

export const useOrganization = (userId: number | null) => {
  const [organization, setOrganization] = useState<Organization | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchOrganization = async () => {
    if (!userId) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const response = await fetch(`${API_BASE_URL}/api/organizations/user/${userId}`);
      
      if (!response.ok) {
        if (response.status === 404) {
          // User doesn't have an organization yet
          setOrganization(null);
          setError(null);
        } else {
          throw new Error(`Failed to fetch organization: ${response.statusText}`);
        }
      } else {
        const data = await response.json();
        // Backend returns { success: true, data: organization }
        // Normalize to the organization object for consumers
        if (data && data.success && data.data) {
          setOrganization(data.data);
        } else {
          // Fallback: if backend returned raw organization, use it
          setOrganization(data);
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
      console.error('Organization fetch error:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrganization();
  }, [userId]);

  const refetch = () => {
    fetchOrganization();
  };

  return {
    organization,
    loading,
    error,
    refetch
  };
};