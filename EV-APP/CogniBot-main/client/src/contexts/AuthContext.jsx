import React, { createContext, useContext, useEffect, useState } from 'react';
import { 
    createUserWithEmailAndPassword, 
    signInWithEmailAndPassword, 
    signOut, 
    onAuthStateChanged,
    updateProfile,
    GoogleAuthProvider,
    signInWithPopup
} from 'firebase/auth';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../lib/firebase';

const AuthContext = createContext();

export function useAuth() {
    return useContext(AuthContext);
}

export function AuthProvider({ children }) {
    const [currentUser, setCurrentUser] = useState(null);
    const [loading, setLoading] = useState(true);

    async function signup(email, password, name) {
        const userCredential = await createUserWithEmailAndPassword(auth, email, password);
        if (name) {
            await updateProfile(userCredential.user, { displayName: name });
        }
        
        const isSuperAdmin = email.trim().toLowerCase() === 'admin-ev@gmail.com';
        
        // Create user document matching flutter schema
        await setDoc(doc(db, 'users', userCredential.user.uid), {
            name: name || (isSuperAdmin ? 'Super Admin' : ''),
            email: email,
            walletBalance: isSuperAdmin ? 10000.0 : 0.0,
            createdAt: serverTimestamp(),
            role: isSuperAdmin ? 'admin' : 'user'
        });
        
        return userCredential;
    }

    async function login(email, password) {
        const trimmedEmail = email.trim().toLowerCase();
        if (trimmedEmail === 'admin-ev@gmail.com' && password === 'admin@ev') {
            try {
                return await signInWithEmailAndPassword(auth, trimmedEmail, password);
            } catch (err) {
                console.log("Login failed for admin-ev@gmail.com:", err.code);
                // If user doesn't exist or credentials mismatch, we attempt to register it
                if (err.code === 'auth/user-not-found' || err.code === 'auth/invalid-credential') {
                    console.log("Super admin account not found. Registering...");
                    try {
                        return await signup(trimmedEmail, password, 'Super Admin');
                    } catch (signUpErr) {
                        console.error("Auto-registration of super admin failed:", signUpErr);
                        throw err; // Throw the original login error if signup fails (e.g. password mismatch on existing account)
                    }
                }
                throw err;
            }
        }
        return signInWithEmailAndPassword(auth, email, password);
    }

    async function signInWithGoogle() {
        const provider = new GoogleAuthProvider();
        const userCredential = await signInWithPopup(auth, provider);
        
        // Check if user exists in database, if not create profile
        const docRef = doc(db, 'users', userCredential.user.uid);
        const docSnap = await getDoc(docRef);
        
        if (!docSnap.exists()) {
            const isSuperAdmin = userCredential.user.email.toLowerCase().trim() === 'admin-ev@gmail.com';
            await setDoc(docRef, {
                name: userCredential.user.displayName || '',
                email: userCredential.user.email,
                walletBalance: isSuperAdmin ? 10000.0 : 0.0,
                createdAt: serverTimestamp(),
                role: isSuperAdmin ? 'admin' : 'user'
            });
        }
        
        return userCredential;
    }

    function logout() {
        return signOut(auth);
    }

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (user) => {
            if (user) {
                try {
                    const docRef = doc(db, 'users', user.uid);
                    const docSnap = await getDoc(docRef);
                    let profileData = docSnap.exists() ? docSnap.data() : null;
                    
                    const isSuperAdmin = user.email && user.email.toLowerCase().trim() === 'admin-ev@gmail.com';
                    
                    if (isSuperAdmin) {
                        if (!profileData) {
                            profileData = {
                                name: 'Super Admin',
                                email: user.email,
                                walletBalance: 10000.0,
                                createdAt: new Date(),
                                role: 'admin'
                            };
                            await setDoc(docRef, profileData);
                            console.log("Auto-created Firestore document for Super Admin.");
                        } else if (profileData.role !== 'admin') {
                            profileData.role = 'admin';
                            await setDoc(docRef, { role: 'admin' }, { merge: true });
                            console.log("Enforced role: 'admin' in Firestore for Super Admin.");
                        }
                    }
                    
                    if (profileData) {
                        setCurrentUser({ ...user, profile: profileData });
                    } else {
                        setCurrentUser(user);
                    }
                } catch (error) {
                    console.error("Error fetching user profile:", error);
                    setCurrentUser(user);
                }
            } else {
                setCurrentUser(null);
            }
            setLoading(false);
        });

        return unsubscribe;
    }, []);

    const value = {
        currentUser,
        login,
        signup,
        signInWithGoogle,
        logout
    };

    return (
        <AuthContext.Provider value={value}>
            {!loading && children}
        </AuthContext.Provider>
    );
}
