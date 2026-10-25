//
//  BhagavadGitaEngine.swift
//  Muhurta
//
//  Comprehensive offline repository of Śrīmad Bhagavad Gītā.
//  Includes all 18 Adhyāyas (Chapters), daily meditative shlokas, Sanskrit Devanagari text,
//  IAST transliteration, English translations, and philosophical reflections for daily contemplation.
//

import Foundation

public struct GitaVerse: Identifiable, Sendable {
    public let id: String
    public let chapter: Int
    public let verse: Int
    public let sanskrit: String
    public let transliteration: String
    public let englishTranslation: String
    public let purport: String
    
    public init(chapter: Int, verse: Int, sanskrit: String, transliteration: String, englishTranslation: String, purport: String) {
        self.id = "BG_\(chapter)_\(verse)"
        self.chapter = chapter
        self.verse = verse
        self.sanskrit = sanskrit
        self.transliteration = transliteration
        self.englishTranslation = englishTranslation
        self.purport = purport
    }
}

public struct GitaChapter: Identifiable, Sendable {
    public let id: Int
    public let number: Int
    public let sanskritName: String
    public let transliteratedName: String
    public let englishTitle: String
    public let verseCount: Int
    public let essence: String
    public let iconName: String
    public let keyVerses: [GitaVerse]
    
    public init(number: Int, sanskritName: String, transliteratedName: String, englishTitle: String, verseCount: Int, essence: String, iconName: String, keyVerses: [GitaVerse]) {
        self.id = number
        self.number = number
        self.sanskritName = sanskritName
        self.transliteratedName = transliteratedName
        self.englishTitle = englishTitle
        self.verseCount = verseCount
        self.essence = essence
        self.iconName = iconName
        self.keyVerses = keyVerses
    }
}

public final class BhagavadGitaEngine: Sendable {
    public static let shared = BhagavadGitaEngine()
    
    public let chapters: [GitaChapter]
    
    private init() {
        self.chapters = Self.loadAllChapters()
    }
    
    /// Returns the sacred Shloka for today's contemplation based on calendar day.
    public func dailyShloka(for date: Date = Date()) -> GitaVerse {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let allFeatured = chapters.flatMap { $0.keyVerses }
        guard !allFeatured.isEmpty else {
            return Self.fallbackVerse
        }
        let index = abs(dayOfYear) % allFeatured.count
        return allFeatured[index]
    }
    
    private static let fallbackVerse = GitaVerse(
        chapter: 2,
        verse: 47,
        sanskrit: "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।\nमा कर्मफलहेतुर्भूर्मा ते सङ्गोऽस्त्वकर्मणि॥",
        transliteration: "karmaṇy-evādhikāras te mā phaleṣu kadācana |\nmā karma-phala-hetur bhūr mā te saṅgo 'stv akarmaṇi ||",
        englishTranslation: "You have a divine right to perform your prescribed duties, but never to the fruits of your actions. Let not the fruits of action be your motive, nor let your attachment be to inaction.",
        purport: "The cardinal foundation of Karma Yoga. By releasing obsession over external results, you act with absolute poise, purity, and supreme mastery in the eternal present."
    )
    
    private static func loadAllChapters() -> [GitaChapter] {
        return [
            GitaChapter(
                number: 1,
                sanskritName: "अर्जुनविषादयोगः",
                transliteratedName: "Arjuna Viṣāda Yoga",
                englishTitle: "The Yoga of Arjuna's Despondency",
                verseCount: 47,
                essence: "Arjuna confronts the sacred battlefield of Kurukṣetra, overcome with grief, moral crisis, and the surrender that awakens divine teaching.",
                iconName: "flag.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 1,
                        verse: 28,
                        sanskrit: "दृष्ट्वेमं स्वजनं कृष्ण युयुत्सुं समुपस्थितम्।\nसीदन्ति मम गात्राणि मुखं च परिशुष्यति॥",
                        transliteration: "dṛṣṭvemaṁ sva-janaṁ kṛṣṇa yuyutsuṁ samupasthitam |\nsīdanti mama gātrāṇi mukhaṁ ca pariśuṣyati ||",
                        englishTranslation: "Arjuna said: O Kṛṣṇa, seeing my kin gathered here eager for battle, my limbs fail me and my mouth is parched.",
                        purport: "The sacred crisis of the human soul. Compassion when untempered by cosmic duty brings paralysis, setting the stage for Lord Kṛṣṇa's timeless wisdom."
                    )
                ]
            ),
            GitaChapter(
                number: 2,
                sanskritName: "सांख्ययोगः",
                transliteratedName: "Sāṅkhya Yoga",
                englishTitle: "The Yoga of Analytical Knowledge",
                verseCount: 72,
                essence: "The immortality of the Ātman (Soul), the nature of selfless duty (Karma Yoga), and the serene mastery of the Sthitaprajña (steadfast sage).",
                iconName: "brain.head.profile",
                keyVerses: [
                    GitaVerse(
                        chapter: 2,
                        verse: 20,
                        sanskrit: "न जायते म्रियते वा कदाचि-\nन्नायं भूत्वा भविता वा न भूयः।\nअजो नित्यः शाश्वतोऽयं पुराणो\nन हन्यते हन्यमाने शरीरे॥",
                        transliteration: "na jāyate mriyate vā kadācin\nnāyaṁ bhūtvā bhavitā vā na bhūyaḥ |\najo nityaḥ śāśvato 'yaṁ purāṇo\nna hanyate hanyamāne śarīre ||",
                        englishTranslation: "The soul is never born, nor does it ever die; nor having once existed, does it ever cease to be. Unborn, eternal, ever-existing, and primeval, it is not slain when the body is slain.",
                        purport: "The ultimate revelation of your true identity. You are not this mortal shell; you are the eternal, invulnerable witness of all cosmic phenomena."
                    ),
                    GitaVerse(
                        chapter: 2,
                        verse: 47,
                        sanskrit: "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।\nमा कर्मफलहेतुर्भूर्मा ते सङ्गोऽस्त्वकर्मणि॥",
                        transliteration: "karmaṇy-evādhikāras te mā phaleṣu kadācana |\nmā karma-phala-hetur bhūr mā te saṅgo 'stv akarmaṇi ||",
                        englishTranslation: "You have a right to your duty, but never to the fruits of action. Let not the fruit of action be your motive, nor let your attachment be to inaction.",
                        purport: "Perform every action as an offering to the Divine without anxiety for the outcome. In pure focus and detachment lies supreme peace and excellence."
                    ),
                    GitaVerse(
                        chapter: 2,
                        verse: 62,
                        sanskrit: "ध्यायतो विषयान्पुंसः सङ्गस्तेषूपजायते।\nसङ्गात्सञ्जायते कामः कामात्क्रोधोऽभिजायते॥",
                        transliteration: "dhyāyato viṣayān puṁsaḥ saṅgas teṣūpajāyate |\nsaṅgāt sañjāyate kāmaḥ kāmāt krodho 'bhijāyate ||",
                        englishTranslation: "While contemplating sense objects, attachment to them arises. From attachment develops desire, and from unfulfilled desire springs anger.",
                        purport: "Lord Kṛṣṇa charts the psychological chain of spiritual downfall, showing why meditative stillness and mindful guardianship of the senses is essential."
                    )
                ]
            ),
            GitaChapter(
                number: 3,
                sanskritName: "कर्मयोगः",
                transliteratedName: "Karma Yoga",
                englishTitle: "The Yoga of Action",
                verseCount: 43,
                essence: "Dedication of all worldly labor as sacred Yajña (sacrifice). Leadership through righteous duty without selfish clinging.",
                iconName: "hands.sparkles.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 3,
                        verse: 19,
                        sanskrit: "तस्मादसक्तः सततं कार्यं कर्म समाचर।\nअसक्तो ह्याचरन्कर्म परमाप्नोति पूरुषः॥",
                        transliteration: "tasmād asaktaḥ satataṁ kāryaṁ karma samācara |\nasakto hy ācaran karma param āpnoti pūruṣaḥ ||",
                        englishTranslation: "Therefore, without being attached, always perform the work that ought to be done; for by working without attachment, a person attains the Supreme.",
                        purport: "True renunciation is not abandoning work, but relinquishing egotistical desire from the heart while executing duty impeccably."
                    ),
                    GitaVerse(
                        chapter: 3,
                        verse: 21,
                        sanskrit: "यद्यदाचरति श्रेष्ठस्तत्तदेवेतरो जनः।\nस यत्प्रमाणं कुरुते लोकस्तदनुवर्तते॥",
                        transliteration: "yad yad ācarati śreṣṭhas tat tad evetaro janaḥ |\nsa yat pramāṇaṁ kurute lokas tad anuvartate ||",
                        englishTranslation: "Whatever action a noble person performs, common people follow. Whatever standards they set by exemplary acts, the entire world pursues.",
                        purport: "The Vedic call to leadership. Lead through silent integrity and dharmic righteousness, uplifting all who cross your path."
                    )
                ]
            ),
            GitaChapter(
                number: 4,
                sanskritName: "ज्ञानकर्मसंन्यासयोगः",
                transliteratedName: "Jñāna Karma Sannyāsa Yoga",
                englishTitle: "The Yoga of Wisdom in Action",
                verseCount: 42,
                essence: "The cosmic descent of the Avatar, ancient lineage of sacred wisdom, and how the fire of spiritual insight burns all karmic impurities to ashes.",
                iconName: "flame.circle.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 4,
                        verse: 7,
                        sanskrit: "यदा यदा हि धर्मस्य ग्लानिर्भवति भारत।\nअभ्युत्थानमधर्मस्य तदात्मानं सृजाम्यहम्॥",
                        transliteration: "yadā yadā hi dharmasya glānir bhavati bhārata |\nabhyutthānam adharmasya tadātmānaṁ sṛjāmy aham ||",
                        englishTranslation: "Whenever and wherever there is a decline in righteousness, O descendant of Bharata, and an ascent of unrighteousness, at that time I descend Myself.",
                        purport: "The eternal promise of divine incarnation. When cosmic balance is threatened, the Divine manifests to restore dharma and awaken the light in humanity."
                    ),
                    GitaVerse(
                        chapter: 4,
                        verse: 8,
                        sanskrit: "परित्राणाय साधूनां विनाशाय च दुष्कृताम्।\nधर्मसंस्थापनार्थाय सम्भवामि युगे युगे॥",
                        transliteration: "paritrāṇāya sādhūnāṁ vināśāya ca duṣkṛtām |\ndharma-saṁsthāpanārthāya sambhavāmi yuge yuge ||",
                        englishTranslation: "For the protection of the good, for the destruction of the wicked, and for the firm establishment of dharma, I appear millenium after millenium.",
                        purport: "The universal mission of divine consciousness in every age (yuga)."
                    )
                ]
            ),
            GitaChapter(
                number: 5,
                sanskritName: "कर्मसंन्यासयोगः",
                transliteratedName: "Karma Sannyāsa Yoga",
                englishTitle: "The Yoga of Renunciation",
                verseCount: 29,
                essence: "Harmonizing outward action with inward meditation. He who acts like a lotus leaf on water remains untouched by sorrow.",
                iconName: "leaf.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 5,
                        verse: 10,
                        sanskrit: "ब्रह्मण्याधाय कर्माणि सङ्गं त्यक्त्वा करोति यः।\nलिप्यते न स पापेन पद्मपत्रमिवाम्भसा॥",
                        transliteration: "brahmaṇy ādhāya karmāṇi saṅgaṁ tyaktvā karoti yaḥ |\nlipyate na sa pāpena padma-patram ivāmbhasā ||",
                        englishTranslation: "One who dedicates all actions to the Supreme, abandoning all selfish attachment, remains untouched by sin just as a lotus leaf is unaffected by water.",
                        purport: "The exquisite metaphor of the lotus: rooted in muddy waters yet blooming untainted in pristine beauty towards the sun."
                    )
                ]
            ),
            GitaChapter(
                number: 6,
                sanskritName: "ध्यानयोगः",
                transliteratedName: "Dhyāna Yoga",
                englishTitle: "The Yoga of Meditation",
                verseCount: 47,
                essence: "The science of sitting in meditation, breath regulation (Prāṇāyāma), mastering the turbulent mind, and the eternal friendship of the soul with itself.",
                iconName: "figure.mind.and.body",
                keyVerses: [
                    GitaVerse(
                        chapter: 6,
                        verse: 5,
                        sanskrit: "उद्धरेदात्मनात्मानं नात्मानमवसादयेत्।\nआत्मैव ह्यात्मनो बन्धुरात्मैव रिपुरात्मनः॥",
                        transliteration: "uddhared ātmanātmānaṁ nātmānam avasādayet |\nātmaiva hy ātmano bandhur ātmaiva ripur ātmanaḥ ||",
                        englishTranslation: "One must elevate oneself by one's own mind, and not degrade oneself. For the mind alone is the dearest friend of the conditioned soul, and the mind is its greatest enemy.",
                        purport: "A mastered mind is your celestial guide; an uncontrolled mind is your fiercest adversary. Take sovereignty over your inner attention."
                    ),
                    GitaVerse(
                        chapter: 6,
                        verse: 26,
                        sanskrit: "यतो यतो निश्चरति मनश्चञ्चलमस्थिरम्।\nततस्ततो नियम्यैतदात्मन्येव वशं नयेत्॥",
                        transliteration: "yato yato niścarati manaś cañcalam asthiram |\ntatas tato niyamyaitad ātmany eva vaśaṁ nayet ||",
                        englishTranslation: "From wherever the restless and unsteady mind wanders away, one should surely restrain it and bring it back under the subjugation of the Self.",
                        purport: "The golden technique of Dhyāna: gentle, patient, unwavering return of attention to the inner divine core."
                    )
                ]
            ),
            GitaChapter(
                number: 7,
                sanskritName: "ज्ञानविज्ञानयोगः",
                transliteratedName: "Jñāna Vijñāna Yoga",
                englishTitle: "The Yoga of Knowledge and Wisdom",
                verseCount: 30,
                essence: "The cosmic energies of the Divine (Prakṛti and Puruṣa), the thread strung through all jewels, and the four types of virtuous souls who seek God.",
                iconName: "sparkle.magnifyingglass",
                keyVerses: [
                    GitaVerse(
                        chapter: 7,
                        verse: 7,
                        sanskrit: "मत्तः परतरं नान्यत्किञ्चिदस्ति धनञ्जय।\nमयि सर्वमिदं प्रोतं सूत्रे मणिगणा इव॥",
                        transliteration: "mattaḥ parataraṁ nānyat kiñcid asti dhanañjaya |\nmayi sarvam idaṁ protaṁ sūtre maṇi-gaṇā iva ||",
                        englishTranslation: "There is nothing whatsoever superior to Me, O Conqueror of Wealth. Everything rests upon Me, like pearls strung on a sacred cosmic thread.",
                        purport: "Behold the unity underlying all diversity. Every atom, star, and living being is threaded on the single consciousness of the Divine."
                    )
                ]
            ),
            GitaChapter(
                number: 8,
                sanskritName: "अक्षरब्रह्मयोगः",
                transliteratedName: "Akṣara Brahma Yoga",
                englishTitle: "The Yoga of the Imperishable Absolute",
                verseCount: 28,
                essence: "The mystery of death and transition, the sacred syllable OM (ॐ), and the two cosmic paths of the sun (Uttarāyaṇa and Dakṣiṇāyana).",
                iconName: "infinity.circle.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 8,
                        verse: 5,
                        sanskrit: "अन्तकाले च मामेव स्मरन्मुक्त्वा कलेवरम्।\nयः प्रयाति स मद्भावं याति नास्त्यत्र संशयः॥",
                        transliteration: "anta-kāle ca mām eva smaran muktvā kalevaram |\nyaḥ prayāti sa mad-bhāvaṁ yāti nāsty atra saṁśayaḥ ||",
                        englishTranslation: "Whoever, at the end of life, leaves their physical frame remembering Me alone, immediately attains My divine state; of this there is no doubt.",
                        purport: "What occupies your consciousness throughout life determines your final transition. Continual remembrance of the Divine secures supreme liberation."
                    )
                ]
            ),
            GitaChapter(
                number: 9,
                sanskritName: "राजविद्याराजगुह्ययोगः",
                transliteratedName: "Rāja Vidyā Rāja Guhya Yoga",
                englishTitle: "The Yoga of Sovereign Knowledge and Secret",
                verseCount: 34,
                essence: "The king of all sciences, purest knowledge directly realizable, the supreme promise of total protection for those surrendered in pure devotion.",
                iconName: "crown.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 9,
                        verse: 22,
                        sanskrit: "अनन्याश्चिन्तयन्तो मां ये जनाः पर्युपासते।\nतेषां नित्याभियुक्तानां योगक्षेमं वहाम्यहम्॥",
                        transliteration: "ananyāś cintayanto māṁ ye janāḥ paryupāsate |\nteṣāṁ nityābhiyuktānāṁ yoga-kṣemaṁ vahāmy aham ||",
                        englishTranslation: "To those who always contemplate Me with undivided devotion, I personally preserve what they have and provide what they lack (Yoga-Kṣema).",
                        purport: "The supreme covenant of divine grace. When your mind rests completely in the Divine, the cosmos orchestrates and safeguards your well-being."
                    ),
                    GitaVerse(
                        chapter: 9,
                        verse: 26,
                        sanskrit: "पत्रं पुष्पं फलं तोयं यो मे भक्त्या प्रयच्छति।\nतदहं भक्त्युपहृतमश्नामि प्रयतात्मनः॥",
                        transliteration: "patraṁ puṣpaṁ phalaṁ toyaṁ yo me bhaktyā prayacchati |\ntad ahaṁ bhakty-upahṛtam aśnāmi prayatātmanaḥ ||",
                        englishTranslation: "Whoever offers Me with true love and devotion a simple leaf, a flower, a fruit, or even pure water, I accept that loving gift from a pure-hearted seeker.",
                        purport: "The Divine seeks not grand material displays, but the humble purity of your loving heart."
                    )
                ]
            ),
            GitaChapter(
                number: 10,
                sanskritName: "विभूतियोगः",
                transliteratedName: "Vibhūti Yoga",
                englishTitle: "The Yoga of Divine Opulences",
                verseCount: 42,
                essence: "How to see the Divine in everything: among lights the Sun, among mountains the Himalayas, among waters the Ganges, and among letters the letter 'A'.",
                iconName: "sun.dust.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 10,
                        verse: 41,
                        sanskrit: "यद्यद्विभूतिमत्सत्त्वं श्रीमदूर्जितमेव वा।\nतत्तदेवावगच्छ त्वं मम तेजोऽंशसम्भवम्॥",
                        transliteration: "yad yad vibhūtimat sattvaṁ śrīmad ūrjitam eva vā |\ntat tad evāvagaccha tvaṁ mama tejo-'ṁśa-sambhavam ||",
                        englishTranslation: "Whatever state of being is radiant, prosperous, beautiful, or mighty—know that to be born of a mere spark of My divine splendor.",
                        purport: "Whenever you witness beauty, brilliance, or genius anywhere in creation, bow your head: it is the radiance of God expressing through form."
                    )
                ]
            ),
            GitaChapter(
                number: 11,
                sanskritName: "विश्वरूपदर्शनयोगः",
                transliteratedName: "Viśvarūpa Darśana Yoga",
                englishTitle: "The Vision of the Universal Cosmic Form",
                verseCount: 55,
                essence: "Lord Kṛṣṇa grants Arjuna celestial vision (Divya Cakṣu) to witness the terrifying and awe-inspiring totality of the Cosmos as Time itself.",
                iconName: "eye.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 11,
                        verse: 12,
                        sanskrit: "दिवि सूर्यसहस्रस्य भवेद्युगपदुत्थिता।\nयदि भाः सदृशी सा स्याद्भासस्तस्य महात्मनः॥",
                        transliteration: "divi sūrya-sahasrasya bhaved yugapad utthitā |\nyadi bhāḥ sadṛśī sā syād bhāsas tasya mahātmanaḥ ||",
                        englishTranslation: "If the radiance of a thousand suns were to blaze forth at once in the celestial sky, that might resemble the glory of that Supreme Being.",
                        purport: "The blazing cosmic majesty that transcends all comprehension, witnessed by Arjuna with sacred reverence."
                    ),
                    GitaVerse(
                        chapter: 11,
                        verse: 32,
                        sanskrit: "कालोऽस्मि लोकक्षयकृत्प्रवृद्धो\nलोकान्समाहर्तुमिह प्रवृत्ततः।",
                        transliteration: "kālo 'smi loka-kṣaya-kṛt pravṛddho\nlokān samāhartum iha pravṛttaḥ |",
                        englishTranslation: "I am Time, the great destroyer of worlds, manifested here to swallow up this universe.",
                        purport: "Time (Kāla) is the ultimate reality through which the cosmic order continuously births, sustains, and dissolves all worlds."
                    )
                ]
            ),
            GitaChapter(
                number: 12,
                sanskritName: "भक्तियोगः",
                transliteratedName: "Bhakti Yoga",
                englishTitle: "The Yoga of Pure Devotion",
                verseCount: 20,
                essence: "The path of love and total surrender. The characteristics of the devotee most dear to the Divine: free from malice, forgiving, and tranquil.",
                iconName: "heart.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 12,
                        verse: 15,
                        sanskrit: "यस्मान्नोद्विजते लोको लोकान्नोद्विजते च यः।\nहर्षामर्षभयोद्वेगैर्मुक्तो यः स च मे प्रियः॥",
                        transliteration: "yasmān nodvijate loko lokān nodvijate ca yaḥ |\nharṣāmarṣa-bhayodvegair mukto yaḥ sa ca me priyaḥ ||",
                        englishTranslation: "One by whom the world is never agitated, and who is never agitated by the world, free from the grips of elated excitement, intolerance, fear, and anxiety—that soul is exceedingly dear to Me.",
                        purport: "The hallmark of genuine spirituality is non-agitation. You become a sanctuary of calm for everyone around you."
                    )
                ]
            ),
            GitaChapter(
                number: 13,
                sanskritName: "क्षेत्रक्षेत्रज्ञविभागयोगः",
                transliteratedName: "Kṣetra Kṣetrajña Vibhāga Yoga",
                englishTitle: "The Yoga of the Field and the Knower",
                verseCount: 35,
                essence: "Distinguishing the body and mind (the Field) from the immortal observer within (the Knower of the Field).",
                iconName: "square.grid.3x3.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 13,
                        verse: 2,
                        sanskrit: "इदं शरीरं कौन्तेय क्षेत्रमित्यभिधीयते।\nएतद्यो वेत्ति तं प्राहुः क्षेत्रज्ञ इति तद्विदः॥",
                        transliteration: "idaṁ śarīraṁ kaunteya kṣetram ity abhidhīyate |\netad yo vetti taṁ prāhuḥ kṣetra-jña iti tad-vidaḥ ||",
                        englishTranslation: "This physical frame, O son of Kuntī, is called the Field; and one who knows this Field is designated as the Knower by the wise.",
                        purport: "Recognize that your thoughts, feelings, and body are observed objects; you are the silent, pure, luminous Observer."
                    )
                ]
            ),
            GitaChapter(
                number: 14,
                sanskritName: "गुणत्रयविभागयोगः",
                transliteratedName: "Guṇatraya Vibhāga Yoga",
                englishTitle: "The Yoga of the Three Modes of Nature",
                verseCount: 27,
                essence: "The three forces of material nature: Sattva (purity and illumination), Rajas (passion and restless ambition), and Tamas (inertia and darkness).",
                iconName: "triangle.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 14,
                        verse: 6,
                        sanskrit: "तत्र सत्त्वं निर्मलत्वात्प्रकाशकमनामयम्।\nसुखसङ्गेन बध्नाति ज्ञानसङ्गेन चानघ॥",
                        transliteration: "tatra sattvaṁ nirmalatvāt prakāśakam anāmayam |\nsukha-saṅgena badhnāti jñāna-saṅgena cānagha ||",
                        englishTranslation: "Among these, Sattva, being luminous and pure, illuminates and frees from disease; it binds through attachment to happiness and knowledge.",
                        purport: "Cultivate Sattva through pure food, holy muhūrtas, noble associations, and tranquil contemplation."
                    )
                ]
            ),
            GitaChapter(
                number: 15,
                sanskritName: "पुरुषोत्तमयोगः",
                transliteratedName: "Puruṣottama Yoga",
                englishTitle: "The Yoga of the Supreme Divine Being",
                verseCount: 20,
                essence: "The inverted cosmic banyan tree (Aśvattha), the spark residing in the heart of all beings, and the Supreme Person beyond mortal and immortal.",
                iconName: "tree.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 15,
                        verse: 15,
                        sanskrit: "सर्वस्य चाहं हृदि सन्निविष्टो\nमत्तः स्मृतिर्ज्ञानमपोहनं च।\nवेदैश्च सर्वैरहमेव वेद्यो\nवेदान्तकृद्वेदविदेव चाहम्॥",
                        transliteration: "sarvasya cāhaṁ hṛdi sanniviṣṭo\nmattaḥ smṛtir jñānam apohanaṁ ca |\nvedaiś ca sarvair aham eva vedyo\nvedānta-kṛd veda-vid eva cāham ||",
                        englishTranslation: "I am seated deep in the hearts of all living beings; from Me come memory, knowledge, and their loss. By all the Vedas, I alone am to be known; I am indeed the author of Vedānta and the knower of the Vedas.",
                        purport: "The Divine is not distant or unreachable in the heavens; it beats right inside your heart as your innermost self."
                    )
                ]
            ),
            GitaChapter(
                number: 16,
                sanskritName: "दैवासुरसम्पद्विभागयोगः",
                transliteratedName: "Daivāsura Sampad Vibhāga Yoga",
                englishTitle: "The Yoga of Divine and Demonic Natures",
                verseCount: 24,
                essence: "The 26 celestial virtues: fearlessness, purity of heart, steadfastness in knowledge, charity, restraint; and the three gates to self-destruction: lust, anger, greed.",
                iconName: "shield.lefthalf.filled",
                keyVerses: [
                    GitaVerse(
                        chapter: 16,
                        verse: 1,
                        sanskrit: "अभयं सत्त्वसंशुद्धिर्ज्ञानयोगव्यवस्थितिः।\nदानं दमश्च यज्ञश्च स्वाध्यायस्तप आर्जवम्॥",
                        transliteration: "abhayaṁ sattva-saṁśuddhir jñāna-yoga-vyavasthitiḥ |\ndānaṁ damaś ca yajñaś ca svādhyāyas tapa ārjavam ||",
                        englishTranslation: "Fearlessness, purification of one's existence, cultivation of spiritual knowledge, charity, self-restraint, performance of sacrifice, study of sacred texts, penance, and simplicity...",
                        purport: "The sovereign blueprint for spiritual elevation. When fear dissolves and simplicity enters, divine nature blossoms."
                    )
                ]
            ),
            GitaChapter(
                number: 17,
                sanskritName: "श्रद्धात्रयविभागयोगः",
                transliteratedName: "Śraddhātraya Vibhāga Yoga",
                englishTitle: "The Yoga of the Threefold Faith",
                verseCount: 28,
                essence: "How faith, food, sacrifice, austerity, and charity are colored by the three gunas. The mystic potency of OM TAT SAT (ॐ तत् सत्).",
                iconName: "flame.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 17,
                        verse: 3,
                        sanskrit: "सत्त्वानुरूपा सर्वस्य श्रद्धा भवति भारत।\nश्रद्धामयोऽयं पुरुषो यो यच्छ्रद्धः स एव सः॥",
                        transliteration: "sattvānurūpā sarvasya śraddhā bhavati bhārata |\nśraddhā-mayo 'yaṁ puruṣo yo yac-chraddhaḥ sa eva saḥ ||",
                        englishTranslation: "The faith of each person conforms to their mental constitution, O Bhārata. A person is made of their faith; whatever their faith is, that indeed they are.",
                        purport: "You become what you deeply believe and cherish. Shape your faith towards highest truth and your life will transform accordingly."
                    )
                ]
            ),
            GitaChapter(
                number: 18,
                sanskritName: "मोक्षसंन्यासयोगः",
                transliteratedName: "Mokṣa Sannyāsa Yoga",
                englishTitle: "The Yoga of Ultimate Liberation & Surrender",
                verseCount: 78,
                essence: "The crowning synthesis of all spiritual paths. Abandoning all anxiety of dogmas and resting in supreme surrender to the Divine.",
                iconName: "sun.horizon.fill",
                keyVerses: [
                    GitaVerse(
                        chapter: 18,
                        verse: 65,
                        sanskrit: "मन्मना भव मद्भक्तो मद्याजी मां नमस्कुरु।\nमामेवैष्यसि सत्यं ते प्रतिजाने प्रियोऽसि मे॥",
                        transliteration: "man-manā bhava mad-bhakto mad-yājī māṁ namaskuru |\nmām evaiṣyasi satyaṁ te pratijāne priyo 'si me ||",
                        englishTranslation: "Fix your mind always on Me, become My devotee, worship Me, and offer your prostrations to Me. Thus you will certainly come to Me; I promise you this in truth, for you are dearly beloved to Me.",
                        purport: "The personal pledge of the Divine Lover. Give your heart to the Highest, and the Highest will hold you for eternity."
                    ),
                    GitaVerse(
                        chapter: 18,
                        verse: 66,
                        sanskrit: "सर्वधर्मान्परित्यज्य मामेकं शरणं व्रज।\nअहं त्वा सर्वपापेभ्यो मोक्षयिष्यामि मा शुचः॥",
                        transliteration: "sarva-dharmān parityajya mām ekaṁ śaraṇaṁ vraja |\nahaṁ tvā sarva-pāpebhyo mokṣayiṣyāmi mā śucaḥ ||",
                        englishTranslation: "Abandon all varieties of worldly duties and anxieties, and simply surrender unto Me alone. I shall liberate you from all karmic reactions and distress; do not grieve.",
                        purport: "The Carama Śloka—the supreme final instruction of the Bhagavad Gītā. Unconditional refuge in the Divine dissolves all fear and sorrow."
                    ),
                    GitaVerse(
                        chapter: 18,
                        verse: 78,
                        sanskrit: "यत्र योगेश्वरः कृष्णो यत्र पार्थो धनुर्धरः।\nतत्र श्रीर्विजयो भूतिर्ध्रुवा नीतिर्मतिर्मम॥",
                        transliteration: "yatra yogeśvaraḥ kṛṣṇo yatra pārtho dhanur-dharaḥ |\ntatra śrīr vijayo bhūtir dhruvā nītir matir mama ||",
                        englishTranslation: "Wherever there is Kṛṣṇa, the master of all Yoga, and wherever there is Arjuna, the supreme wielder of the bow, there will surely be fortune, victory, extraordinary prosperity, and steadfast morality.",
                        purport: "When divine wisdom meets righteous human action, victory and auspiciousness are guaranteed in every endeavor of life."
                    )
                ]
            )
        ]
    }
}
