package com.theoreticalmindstech.synaptix

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class AndroidSecureSecretStore(context: Context) {
    private val appContext = context.applicationContext
    private val preferences = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun set(key: String, value: String) {
        require(key.isNotBlank()) { "Secret key cannot be blank." }

        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateSecretKey())

        val encrypted = cipher.doFinal(value.toByteArray(StandardCharsets.UTF_8))
        val encodedIv = Base64.encodeToString(cipher.iv, Base64.NO_WRAP)
        val encodedValue = Base64.encodeToString(encrypted, Base64.NO_WRAP)

        preferences.edit().putString(key, "$encodedIv:$encodedValue").apply()
    }

    fun get(key: String): String? {
        require(key.isNotBlank()) { "Secret key cannot be blank." }

        val encoded = preferences.getString(key, null) ?: return null
        val parts = encoded.split(":", limit = 2)
        if (parts.size != 2) return null

        val iv = Base64.decode(parts[0], Base64.NO_WRAP)
        val encrypted = Base64.decode(parts[1], Base64.NO_WRAP)

        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateSecretKey(), GCMParameterSpec(GCM_TAG_LENGTH, iv))

        return String(cipher.doFinal(encrypted), StandardCharsets.UTF_8)
    }

    fun delete(key: String) {
        require(key.isNotBlank()) { "Secret key cannot be blank." }
        preferences.edit().remove(key).apply()
    }

    fun clear() {
        preferences.edit().clear().apply()
    }

    private fun getOrCreateSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val existing = keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry
        if (existing != null) return existing.secretKey

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEYSTORE
        )
        val keySpec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setRandomizedEncryptionRequired(true)
            .build()

        keyGenerator.init(keySpec)
        return keyGenerator.generateKey()
    }

    companion object {
        private const val PREFS_NAME = "trivia_secure_secrets"
        private const val KEY_ALIAS = "synaptix_secure_store_key"
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val GCM_TAG_LENGTH = 128
    }
}
